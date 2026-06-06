import { createSignal, Show } from "solid-js";
import { Portal } from "solid-js/web";
import { useNavigate } from "@solidjs/router";
import { adjectives, animals, colors, uniqueNamesGenerator } from "unique-names-generator";
import "../../lib/l10n";
import { CopyButton } from "../CopyButton";
import { HowToUploadModal } from "./HowToUploadModal";

const segmenter = new Intl.Segmenter();

const csrfToken = (): string =>
  document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? "";

const jsonHeaders = (): HeadersInit => ({
  "Content-Type": "application/json",
  "X-CSRF-Token": csrfToken(),
});

interface MapshotJson {
  map_id: string;
  unique_id: string;
  name?: string;
  savename?: string;
  surfaces?: { surface_localised_name?: string }[];
  [key: string]: unknown;
}

type I18nError = { msgId: string; msgArgs?: Record<string, string | number> };

type State =
  | { type: "idle" }
  | { type: "instructions" }
  | {
      type: "confirming";
      mapshotJson: MapshotJson;
      fileMap: Map<string, File>;
      mapName: string;
      surfaceCount: number;
      imageCount: number;
      totalBytes: number;
    }
  | { type: "preparing"; prepared: number; total: number }
  | { type: "uploading"; progress: number; total: number }
  | { type: "done"; viewerUrl: string }
  | { type: "error"; error: I18nError };

const generateMapName = (): string => {
  const raw = uniqueNamesGenerator({ dictionaries: [adjectives, colors, animals], separator: " ", style: "lowerCase" });
  return raw.charAt(0).toUpperCase() + raw.slice(1);
};

const formatBytes = (n: number): string => {
  if (n < 1024) return `${n} B`;
  if (n < 1048576) return `${(n / 1024).toFixed(1)} KiB`;
  if (n < 1073741824) return `${(n / 1048576).toFixed(1)} MiB`;
  return `${(n / 1073741824).toFixed(1)} GiB`;
};

const runConcurrent = async (
  tasks: (() => Promise<void>)[],
  limit: number,
  onProgress: (done: number) => void
): Promise<void> => {
  if (tasks.length === 0) return;
  let done = 0;
  let idx = 0;
  const worker = async (): Promise<void> => {
    while (idx < tasks.length) {
      await tasks[idx++]();
      onProgress(++done);
    }
  };
  await Promise.all(Array.from({ length: Math.min(limit, tasks.length) }, worker));
};

const relPath = (file: File): string =>
  file.webkitRelativePath.split("/").slice(1).join("/");


export const UploadModal = (props: { isGuest: boolean }) => {
  const navigate = useNavigate();
  const [state, setState] = createSignal<State>({ type: "idle" });
  const [displayName, setDisplayName] = createSignal("");
  const displayNameCount = () => [...segmenter.segment(displayName())].length;
  const [showHowTo, setShowHowTo] = createSignal(false);
  let inputRef!: HTMLInputElement;

  const openModal = () => {
    setState({ type: "instructions" });
  };

  const openPicker = () => {
    inputRef.value = "";
    inputRef.click();
  };

  const onFilesSelected = async (files: FileList) => {
    const allFiles = Array.from(files);

    const mapshotFile = allFiles.find((f) => relPath(f) === "mapshot.json");
    if (!mapshotFile) {
      setState({ type: "error", error: { msgId: "upload-error-not-found" } });
      return;
    }

    let mapshotJson: MapshotJson;
    try {
      mapshotJson = JSON.parse(await mapshotFile.text()) as MapshotJson;
    } catch {
      setState({ type: "error", error: { msgId: "upload-error-parse" } });
      return;
    }

    const imageFiles = allFiles.filter((f) => relPath(f).endsWith(".jpg"));
    const fileMap = new Map<string, File>();
    for (const f of imageFiles) fileMap.set(relPath(f), f);

    let initialName = mapshotJson.name || mapshotJson.savename || generateMapName();
    let existingMap = false;
    try {
      const resp = await fetch(`/api/v1/maps/lookup?mapshot_map_id=${encodeURIComponent(mapshotJson.map_id)}`);
      if (resp.ok) {
        existingMap = true;
        const data = await resp.json() as { name: string | null };
        if (data.name) initialName = data.name;
      }
    } catch {
      // Use JSON-derived name if lookup fails
    }
    setDisplayName(initialName);
    setState({
      type: "confirming",
      mapshotJson,
      fileMap,
      mapName: initialName,
      surfaceCount: mapshotJson.surfaces?.length ?? 0,
      imageCount: imageFiles.length,
      totalBytes: imageFiles.reduce((sum, f) => sum + f.size, 0),
    });
  };

  const startUpload = async () => {
    const s = state();
    if (s.type !== "confirming") return;

    const { mapshotJson, fileMap } = s;
    const imageCount = fileMap.size;
    setState({ type: "preparing", prepared: 0, total: imageCount });

    // Step 1: POST /api/v1/uploads
    let uploadUlid: string, mapUlid: string, generationUlid: string;
    try {
      const resp = await fetch("/api/v1/uploads", {
        method: "POST",
        headers: jsonHeaders(),
        body: JSON.stringify({ metadata: mapshotJson, total_image_count: imageCount, name: displayName() || s.mapName }),
      });
      if (resp.status === 409) {
        setState({ type: "error", error: { msgId: "upload-error-conflict" } });
        return;
      }
      if (resp.status === 410) {
        setState({ type: "error", error: { msgId: "upload-error-expired" } });
        return;
      }
      if (resp.status === 422) {
        const data = await resp.json() as { error?: string };
        setState({ type: "error", error: { msgId: data.error ?? "error-unknown" } });
        return;
      }
      if (!resp.ok) {
        setState({ type: "error", error: { msgId: "upload-error-http", msgArgs: { status: resp.status } } });
        return;
      }
      const data = await resp.json() as { ulid: string; map_ulid: string; generation_ulid: string };
      uploadUlid = data.ulid;
      mapUlid = data.map_ulid;
      generationUlid = data.generation_ulid;
    } catch {
      setState({ type: "error", error: { msgId: "upload-error-network" } });
      return;
    }

    // Step 2: POST /api/v1/uploads/:ulid/presigned_urls (batched for progress visibility)
    const PRESIGNED_BATCH_SIZE = 200;
    const allFilenames = Array.from(fileMap.keys());
    const presignedUrls: Record<string, string> = {};
    for (let i = 0; i < allFilenames.length; i += PRESIGNED_BATCH_SIZE) {
      const batch = allFilenames.slice(i, i + PRESIGNED_BATCH_SIZE);
      try {
        const resp = await fetch(`/api/v1/uploads/${uploadUlid}/presigned_urls`, {
          method: "POST",
          headers: jsonHeaders(),
          body: JSON.stringify({ filenames: batch }),
        });
        if (!resp.ok) {
          setState({ type: "error", error: { msgId: "upload-error-urls-http", msgArgs: { status: resp.status } } });
          return;
        }
        const data = await resp.json() as { presigned_urls: Record<string, string> };
        Object.assign(presignedUrls, data.presigned_urls);
      } catch {
        setState({ type: "error", error: { msgId: "upload-error-urls-network" } });
        return;
      }
      setState({ type: "preparing", prepared: Math.min(i + PRESIGNED_BATCH_SIZE, allFilenames.length), total: imageCount });
    }

    // Step 3: PUT to S3 via presigned URLs (concurrent, limit 5)
    const alreadyUploaded = imageCount - Object.keys(presignedUrls).length;
    setState({ type: "uploading", progress: alreadyUploaded, total: imageCount });

    const tasks = Object.entries(presignedUrls).map(([filename, url]) => async () => {
      const file = fileMap.get(filename)!;
      const resp = await fetch(url, { method: "PUT", body: file });
      if (!resp.ok) throw new Error(`${filename}: HTTP ${resp.status}`);
    });

    try {
      await runConcurrent(tasks, 5, (done) => {
        setState({ type: "uploading", progress: alreadyUploaded + done, total: imageCount });
      });
    } catch (err) {
      setState({ type: "error", error: { msgId: "upload-error-file", msgArgs: { details: (err as Error).message } } });
      return;
    }

    // Step 4: PATCH /api/v1/uploads/:ulid
    try {
      const resp = await fetch(`/api/v1/uploads/${uploadUlid}`, {
        method: "PATCH",
        headers: jsonHeaders(),
        body: JSON.stringify({ status: "complete" }),
      });
      if (!resp.ok) {
        setState({ type: "error", error: { msgId: "upload-error-finalize" } });
        return;
      }
    } catch {
      setState({ type: "error", error: { msgId: "upload-error-finalize-network" } });
      return;
    }

    const viewerUrl = `/maps/${mapUlid}?generation=${generationUlid}`;
    setState({ type: "done", viewerUrl });
  };

  const dismiss = () => {
    setState({ type: "idle" });
  };

  const confirmingState = () => {
    const s = state();
    return s.type === "confirming" ? s : null;
  };
  const preparingState = () => {
    const s = state();
    return s.type === "preparing" ? s : null;
  };
  const uploadingState = () => {
    const s = state();
    return s.type === "uploading" ? s : null;
  };
  const doneState = () => {
    const s = state();
    return s.type === "done" ? s : null;
  };
  const errorState = () => {
    const s = state();
    return s.type === "error" ? s : null;
  };

  return (
    <>
      <input
        ref={(el) => {
          inputRef = el;
          el.setAttribute("webkitdirectory", "");
        }}
        type="file"
        style={{ display: "none" }}
        onChange={(e) => {
          const files = e.currentTarget.files;
          if (files && files.length > 0) onFilesSelected(files);
        }}
      />
      <div class="buttons has-addons">
        <button
          class="button is-primary"
          onClick={props.isGuest ? undefined : openModal}
          disabled={props.isGuest}
          data-l10n-id={props.isGuest ? "upload-button-guest" : undefined}
        >
          <span class="icon"><i class="fa-solid fa-upload" /></span>
          <span data-l10n-id="upload-button" />
        </button>
        <button class="button" data-l10n-id="how-to-upload-button" onClick={() => setShowHowTo(true)}>
          <span class="icon"><i class="fa-solid fa-circle-question" /></span>
        </button>
      </div>
      <Show when={showHowTo()}>
        <HowToUploadModal onClose={() => setShowHowTo(false)} />
      </Show>
      <Show when={state().type !== "idle"}>
        <Portal mount={document.body}>
        <div class="modal is-active">
          <div class="modal-background" onClick={dismiss} />
          <div class="modal-card" style={{ width: "90vw", "max-width": "1000px" }}>
            <header class="modal-card-head">
              <p class="modal-card-title" data-l10n-id="upload-modal-title" />
              <Show when={state().type !== "uploading" && state().type !== "preparing"}>
                <button class="delete" aria-label="close" onClick={dismiss} />
              </Show>
            </header>
            <section class="modal-card-body">
              <Show when={state().type === "instructions"}>
                <div class="content">
                  <p>
                    <span class="icon-text">
                      <span class="icon"><i class="fa-solid fa-folder-open" /></span>
                      <span data-l10n-id="upload-instructions-folder"><code data-l10n-name="filename">mapshot.json</code></span>
                    </span>
                  </p>
                  <div class="notification is-info is-light">
                    <p class="has-text-weight-semibold mb-2" data-l10n-id="upload-instructions-folder-path" />
                    <ul>
                      <li>
                        <span class="icon-text">
                          <span class="icon"><i class="fa-brands fa-windows" /></span>
                          <span>
                            <code>%APPDATA%\Factorio\script-output\mapshot</code>
                            <CopyButton text="%APPDATA%\Factorio\script-output\mapshot" l10nId="upload-copy-path-windows" class="is-ghost px-1" style={{ "vertical-align": "middle" }} />
                          </span>
                        </span>
                      </li>
                      <li>
                        <span class="icon-text">
                          <span class="icon"><i class="fa-brands fa-apple" /></span>
                          <span>
                            <code>~/Library/Application Support/factorio/script-output/mapshot</code>
                            <CopyButton text="~/Library/Application Support/factorio/script-output/mapshot" l10nId="upload-copy-path-macos" class="is-ghost px-1" style={{ "vertical-align": "middle" }} />
                          </span>
                        </span>
                      </li>
                      <li>
                        <span class="icon-text">
                          <span class="icon"><i class="fa-brands fa-linux" /></span>
                          <span>
                            <code>~/.factorio/script-output/mapshot</code>
                            <CopyButton text="~/.factorio/script-output/mapshot" l10nId="upload-copy-path-linux" class="is-ghost px-1" style={{ "vertical-align": "middle" }} />
                          </span>
                        </span>
                      </li>
                    </ul>
                    <p class="mt-3"><span data-l10n-id="upload-instructions-folder-subfolder" /> <code><var>map-abcd1234</var>/<var>d-abcd1234</var></code></p>
                  </div>
                  <p>
                    <span class="icon-text">
                      <span class="icon"><i class="fa-solid fa-timeline" /></span>
                      <span data-l10n-id="upload-instructions-generations" />
                    </span>
                  </p>
                </div>
              </Show>
              <Show when={confirmingState()} keyed>
                {(s) => (
                  <table class="table is-fullwidth">
                    <tbody>
                      <tr>
                        <th><span class="icon-text"><span class="icon"><i class="fa-solid fa-map" /></span><span data-l10n-id="upload-map-title" /></span></th>
                        <td>
                          <div class="field has-addons mb-0">
                            <span class="control is-expanded">
                              <input
                                ref={(el) => { setTimeout(() => { el.focus(); el.select(); }, 0); }}
                                class="input"
                                type="text"
                                value={displayName()}
                                placeholder={s.mapName}
                                onInput={(e) => setDisplayName(e.currentTarget.value)}
                              />
                            </span>
                            <div class="control">
                              <span class={`button is-static ${displayNameCount() > 30 ? "has-text-danger" : "has-text-grey-light"}`}>
                                {displayNameCount()} / 30
                              </span>
                            </div>
                          </div>
                        </td>
                      </tr>
                      <tr>
                        <th><span class="icon-text"><span class="icon"><i class="fa-solid fa-layer-group" /></span><span data-l10n-id="upload-surfaces" /></span></th>
                        <td>{s.surfaceCount}</td>
                      </tr>
                      <tr>
                        <th><span class="icon-text"><span class="icon"><i class="fa-solid fa-images" /></span><span data-l10n-id="upload-images" /></span></th>
                        <td>{s.imageCount}</td>
                      </tr>
                      <tr>
                        <th><span class="icon-text"><span class="icon"><i class="fa-solid fa-chart-simple" /></span><span data-l10n-id="upload-total-size" /></span></th>
                        <td>{formatBytes(s.totalBytes)}</td>
                      </tr>
                    </tbody>
                  </table>
                )}
              </Show>
              <Show when={preparingState()} keyed>
                {(s) => (
                  <>
                    <p
                      class="mb-2"
                      data-l10n-id="upload-preparing"
                      data-l10n-args={JSON.stringify({ prepared: s.prepared, total: s.total })}
                    />
                    <progress class="progress is-primary" value={s.prepared} max={s.total} />
                  </>
                )}
              </Show>
              <Show when={uploadingState()} keyed>
                {(s) => (
                  <>
                    <p
                      class="mb-2"
                      data-l10n-id="upload-progress"
                      data-l10n-args={JSON.stringify({ progress: s.progress, total: s.total })}
                    />
                    <progress class="progress is-primary" value={s.progress} max={s.total} />
                  </>
                )}
              </Show>
              <Show when={doneState()}>
                {(s) => (
                  <div class="has-text-centered">
                    <p class="mb-4" data-l10n-id="upload-complete" />
                    <button class="button is-primary" data-l10n-id="upload-view-map" onClick={() => { dismiss(); navigate(s().viewerUrl); }} />
                  </div>
                )}
              </Show>
              <Show when={errorState()} keyed>
                {(s) => (
                  <p
                    class="has-text-danger"
                    data-l10n-id={s.error.msgId}
                    data-l10n-args={s.error.msgArgs ? JSON.stringify(s.error.msgArgs) : undefined}
                  />
                )}
              </Show>
            </section>
            <footer class="modal-card-foot">
              <Show when={state().type === "instructions"}>
                <div class="buttons">
                  <button class="button is-primary" onClick={openPicker}>
                    <span class="icon"><i class="fa-solid fa-folder-open" /></span>
                    <span data-l10n-id="upload-select-folder" />
                  </button>
                  <button class="button" data-l10n-id="upload-cancel" onClick={dismiss} />
                </div>
              </Show>
              <Show when={state().type === "confirming"}>
                <div class="buttons">
                  <button class="button" onClick={openPicker}>
                    <span class="icon"><i class="fa-solid fa-folder-open" /></span>
                    <span data-l10n-id="upload-reselect-folder" />
                  </button>
                  <button class="button is-primary" onClick={startUpload} disabled={displayNameCount() > 30}>
                    <span class="icon"><i class="fa-solid fa-upload" /></span>
                    <span data-l10n-id="upload-start" />
                  </button>
                  <button class="button" data-l10n-id="upload-cancel" onClick={dismiss} />
                </div>
              </Show>
              <Show when={state().type === "done"}>
                <div class="buttons">
                  <button class="button" data-l10n-id="upload-close" onClick={dismiss} />
                </div>
              </Show>
              <Show when={state().type === "error"}>
                <div class="buttons">
                  <button class="button is-primary" onClick={openPicker}>
                    <span class="icon"><i class="fa-solid fa-folder-open" /></span>
                    <span data-l10n-id="upload-reselect-folder" />
                  </button>
                  <button class="button" data-l10n-id="upload-dismiss" onClick={dismiss} />
                </div>
              </Show>
            </footer>
          </div>
        </div>
        </Portal>
      </Show>
    </>
  );
};
