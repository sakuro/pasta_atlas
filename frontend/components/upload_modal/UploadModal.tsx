import { createSignal, onFlush, Show } from "solid-js";
import { Portal } from "@solidjs/web";
import { useNavigate } from "@solidjs/router";
import "../../lib/l10n";
import {
  completeUpload,
  createUpload,
  errorKey,
  issuePresignedPosts,
  lookupMap,
  verifyUploadBatch,
} from "../../lib/api/client";
import { countGraphemes, generateMapName, MAX_MAP_NAME_GRAPHEMES } from "../../lib/map-name";
import { notifyUploadCompleted } from "../../lib/upload-events";
import { CopyButton } from "../CopyButton";
import { HowToUploadModal } from "./HowToUploadModal";

const MAX_IMAGE_COUNT = 10_000;

interface MapshotJson {
  map_id: string;
  unique_id: string;
  tick: number;
  savename?: string;
  surfaces?: unknown[];
  [key: string]: unknown;
}

// Checks only what the modal reads and what createUpload requires; the server checks the formats.
const parseMapshotJson = (text: string): MapshotJson | undefined => {
  let value: unknown;
  try {
    value = JSON.parse(text);
  } catch {
    return undefined;
  }
  if (typeof value !== "object" || value === null || Array.isArray(value)) return undefined;
  const fields: Map<string, unknown> = new Map(Object.entries(value));
  const mapId = fields.get("map_id");
  const uniqueId = fields.get("unique_id");
  const tick = fields.get("tick");
  const savename = fields.get("savename");
  const surfaces = fields.get("surfaces");
  if (typeof mapId !== "string" || typeof uniqueId !== "string") return undefined;
  if (typeof tick !== "number" || !Number.isInteger(tick)) return undefined;
  if (savename !== undefined && typeof savename !== "string") return undefined;
  if (surfaces !== undefined && !Array.isArray(surfaces)) return undefined;
  return { ...value, map_id: mapId, unique_id: uniqueId, tick, savename, surfaces };
};

type I18nError = { msgId: string; msgArgs?: Record<string, string | number> };

const createUploadError = (response: Response | undefined, error: unknown): I18nError => {
  if (!response) return { msgId: "upload-error-network" };
  if (response.status === 409) return { msgId: "upload-error-conflict" };
  if (response.status === 422) return { msgId: errorKey(error) ?? "error-unknown" };
  return { msgId: "upload-error-http", msgArgs: { status: response.status } };
};

type State =
  | { type: "idle" }
  | { type: "instructions" }
  | {
      type: "confirming";
      mapshotJson: MapshotJson;
      fileMap: Map<string, File>;
      surfaceCount: number;
      imageCount: number;
      totalBytes: number;
    }
  | { type: "preparing"; prepared: number; total: number }
  | { type: "uploading"; progress: number; total: number }
  | { type: "verifying"; progress: number; total: number }
  | { type: "done"; viewerUrl: string }
  | { type: "error"; error: I18nError };

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

const relPath = (file: File): string => file.webkitRelativePath.split("/").slice(1).join("/");

export const UploadModal = (props: { isGuest: boolean }) => {
  const navigate = useNavigate();
  const [state, setState] = createSignal<State>({ type: "idle" });
  const [displayName, setDisplayName] = createSignal("");
  const uploadName = () => displayName().trim();
  const uploadNameCount = () => countGraphemes(uploadName());
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

    const mapshotJson = parseMapshotJson(await mapshotFile.text());
    if (!mapshotJson) {
      setState({ type: "error", error: { msgId: "upload-error-parse" } });
      return;
    }

    const imageFiles = allFiles.filter((f) => relPath(f).endsWith(".jpg"));
    if (imageFiles.length === 0) {
      setState({ type: "error", error: { msgId: "upload-error-no-images" } });
      return;
    }
    if (imageFiles.length > MAX_IMAGE_COUNT) {
      setState({
        type: "error",
        error: { msgId: "upload-error-too-many-images", msgArgs: { count: imageFiles.length, max: MAX_IMAGE_COUNT } },
      });
      return;
    }
    const fileMap = new Map<string, File>();
    for (const f of imageFiles) fileMap.set(relPath(f), f);

    // The server strips the name and rejects an empty one, so a savename of spaces must not be prefilled.
    let initialName = mapshotJson.savename?.trim() || generateMapName();
    let existingMap = false;
    // On any failure the savename or the generated name stays.
    const { data } = await lookupMap({ query: { mapshot_map_id: mapshotJson.map_id } });
    if (data) {
      existingMap = true;
      initialName = data.display_name;
    }
    setDisplayName(initialName);
    setState({
      type: "confirming",
      mapshotJson,
      fileMap,
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
    const BATCH_SIZE = 200;
    const allFilenames = Array.from(fileMap.keys());

    // Step 1: POST /api/v1/uploads
    const {
      data: upload,
      error,
      response,
    } = await createUpload({
      body: { metadata: mapshotJson, total_image_count: imageCount, display_name: uploadName() },
    });
    if (!upload) {
      setState({ type: "error", error: createUploadError(response, error) });
      return;
    }
    const { ulid: uploadUlid, map_ulid: mapUlid, generation_ulid: generationUlid } = upload;

    // Step 2: Process each batch sequentially: presign → upload → verify
    let uploadedCount = 0;

    for (let i = 0; i < allFilenames.length; i += BATCH_SIZE) {
      const batch = allFilenames.slice(i, i + BATCH_SIZE);

      // 2a. Get presigned URLs for this batch
      setState({ type: "preparing", prepared: i, total: imageCount });
      const { data: presigned, response: presignedResponse } = await issuePresignedPosts({
        path: { ulid: uploadUlid },
        body: { filenames: batch },
      });
      if (!presigned) {
        setState({
          type: "error",
          error: presignedResponse
            ? { msgId: "upload-error-urls-http", msgArgs: { status: presignedResponse.status } }
            : { msgId: "upload-error-urls-network" },
        });
        return;
      }

      // 2b. Upload this batch to S3
      setState({ type: "uploading", progress: uploadedCount, total: imageCount });
      const tasks = Object.entries(presigned.presigned_posts).map(([filename, { url, fields }]) => async () => {
        const file = fileMap.get(filename)!;
        const form = new FormData();
        for (const [k, v] of Object.entries(fields)) form.append(k, v);
        form.append("file", file);
        const resp = await fetch(url, { method: "POST", body: form });
        if (!resp.ok) throw new Error(`${filename}: HTTP ${resp.status}`);
      });
      try {
        await runConcurrent(tasks, 5, (done) => {
          setState({ type: "uploading", progress: uploadedCount + done, total: imageCount });
        });
      } catch (err) {
        setState({
          type: "error",
          error: { msgId: "upload-error-file", msgArgs: { details: (err as Error).message } },
        });
        return;
      }
      uploadedCount += batch.length;

      // 2c. Verify this batch. The bar keeps the count reached by the upload so that it
      // does not fall back while the batch is verified.
      setState({ type: "verifying", progress: uploadedCount, total: imageCount });
      const { data: verified, response: verifyResponse } = await verifyUploadBatch({
        path: { ulid: uploadUlid },
        body: { filenames: batch },
      });
      if (!verified) {
        setState({
          type: "error",
          error: verifyResponse
            ? { msgId: "upload-error-verify-http", msgArgs: { status: verifyResponse.status } }
            : { msgId: "upload-error-verify-network" },
        });
        return;
      }
    }

    // Step 3: PATCH /api/v1/uploads/:ulid complete
    const { data: completed, response: completeResponse } = await completeUpload({
      path: { ulid: uploadUlid },
      body: { status: "complete" },
    });
    if (!completed) {
      setState({
        type: "error",
        error: { msgId: completeResponse ? "upload-error-finalize" : "upload-error-finalize-network" },
      });
      return;
    }

    const viewerUrl = `/maps/${mapUlid}?generation=${generationUlid}`;
    setState({ type: "done", viewerUrl });
    notifyUploadCompleted();
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
  const verifyingState = () => {
    const s = state();
    return s.type === "verifying" ? s : null;
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
          onClick={() => {
            if (!props.isGuest) openModal();
          }}
          disabled={props.isGuest}
          data-l10n-id={props.isGuest ? "upload-button-guest" : undefined}
        >
          <span class="icon">
            <i class="fa-solid fa-upload" />
          </span>
          <span data-l10n-id="upload-button" />
        </button>
        <button class="button" data-l10n-id="how-to-upload-button" onClick={() => setShowHowTo(true)}>
          <span class="icon">
            <i class="fa-solid fa-circle-question" />
          </span>
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
                <Show
                  when={state().type !== "uploading" && state().type !== "preparing" && state().type !== "verifying"}
                >
                  <button class="delete" aria-label="close" onClick={dismiss} />
                </Show>
              </header>
              <section class="modal-card-body">
                <Show when={state().type === "instructions"}>
                  <div class="content">
                    <p>
                      <span class="icon-text">
                        <span class="icon">
                          <i class="fa-solid fa-folder-open" />
                        </span>
                        <span data-l10n-id="upload-instructions-folder">
                          <code data-l10n-name="filename">mapshot.json</code>
                        </span>
                      </span>
                    </p>
                    <div class="notification is-info is-light">
                      <p class="has-text-weight-semibold mb-2" data-l10n-id="upload-instructions-folder-path" />
                      <ul>
                        <li>
                          <span class="icon-text">
                            <span class="icon">
                              <i class="fa-brands fa-windows" />
                            </span>
                            <span>
                              <code>%APPDATA%\Factorio\script-output\mapshot</code>
                              <CopyButton
                                text="%APPDATA%\Factorio\script-output\mapshot"
                                l10nId="upload-copy-path-windows"
                                class="is-ghost px-1"
                                style={{ "vertical-align": "middle" }}
                              />
                            </span>
                          </span>
                        </li>
                        <li>
                          <span class="icon-text">
                            <span class="icon">
                              <i class="fa-brands fa-apple" />
                            </span>
                            <span>
                              <code>~/Library/Application Support/factorio/script-output/mapshot</code>
                              <CopyButton
                                text="~/Library/Application Support/factorio/script-output/mapshot"
                                l10nId="upload-copy-path-macos"
                                class="is-ghost px-1"
                                style={{ "vertical-align": "middle" }}
                              />
                            </span>
                          </span>
                        </li>
                        <li>
                          <span class="icon-text">
                            <span class="icon">
                              <i class="fa-brands fa-linux" />
                            </span>
                            <span>
                              <code>~/.factorio/script-output/mapshot</code>
                              <CopyButton
                                text="~/.factorio/script-output/mapshot"
                                l10nId="upload-copy-path-linux"
                                class="is-ghost px-1"
                                style={{ "vertical-align": "middle" }}
                              />
                            </span>
                          </span>
                        </li>
                      </ul>
                      <p class="mt-3">
                        <span data-l10n-id="upload-instructions-folder-subfolder" />{" "}
                        <code>
                          <var>map-abcd1234</var>/<var>d-abcd1234</var>
                        </code>
                      </p>
                    </div>
                    <p>
                      <span class="icon-text">
                        <span class="icon">
                          <i class="fa-solid fa-timeline" />
                        </span>
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
                          <th>
                            <span class="icon-text">
                              <span class="icon">
                                <i class="fa-solid fa-map" />
                              </span>
                              <span data-l10n-id="upload-map-title" />
                            </span>
                          </th>
                          <td>
                            <div class="field has-addons mb-0">
                              <span class="control is-expanded">
                                <input
                                  ref={(el) => {
                                    setTimeout(() => {
                                      el.focus();
                                      el.select();
                                    }, 0);
                                  }}
                                  class="input"
                                  type="text"
                                  value={displayName()}
                                  onInput={(e) => setDisplayName(e.currentTarget.value)}
                                />
                              </span>
                              <div class="control">
                                <span
                                  class={[
                                    "button is-static",
                                    uploadNameCount() > MAX_MAP_NAME_GRAPHEMES
                                      ? "has-text-danger"
                                      : "has-text-grey-light",
                                  ]}
                                >
                                  {uploadNameCount()} / {MAX_MAP_NAME_GRAPHEMES}
                                </span>
                              </div>
                            </div>
                          </td>
                        </tr>
                        <tr>
                          <th>
                            <span class="icon-text">
                              <span class="icon">
                                <i class="fa-solid fa-layer-group" />
                              </span>
                              <span data-l10n-id="upload-surfaces" />
                            </span>
                          </th>
                          <td>{s.surfaceCount}</td>
                        </tr>
                        <tr>
                          <th>
                            <span class="icon-text">
                              <span class="icon">
                                <i class="fa-solid fa-images" />
                              </span>
                              <span data-l10n-id="upload-images" />
                            </span>
                          </th>
                          <td>{s.imageCount}</td>
                        </tr>
                        <tr>
                          <th>
                            <span class="icon-text">
                              <span class="icon">
                                <i class="fa-solid fa-chart-simple" />
                              </span>
                              <span data-l10n-id="upload-total-size" />
                            </span>
                          </th>
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
                <Show when={verifyingState()} keyed>
                  {(s) => (
                    <>
                      <p
                        class="mb-2"
                        data-l10n-id="upload-verifying"
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
                      <button
                        class="button is-primary"
                        data-l10n-id="upload-view-map"
                        onClick={() => {
                          onFlush(dismiss);
                          navigate(s().viewerUrl);
                        }}
                      />
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
                      <span class="icon">
                        <i class="fa-solid fa-folder-open" />
                      </span>
                      <span data-l10n-id="upload-select-folder" />
                    </button>
                    <button class="button" data-l10n-id="upload-cancel" onClick={dismiss} />
                  </div>
                </Show>
                <Show when={state().type === "confirming"}>
                  <div class="buttons">
                    <button class="button" onClick={openPicker}>
                      <span class="icon">
                        <i class="fa-solid fa-folder-open" />
                      </span>
                      <span data-l10n-id="upload-reselect-folder" />
                    </button>
                    <button
                      class="button is-primary"
                      onClick={startUpload}
                      disabled={uploadNameCount() === 0 || uploadNameCount() > MAX_MAP_NAME_GRAPHEMES}
                    >
                      <span class="icon">
                        <i class="fa-solid fa-upload" />
                      </span>
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
                      <span class="icon">
                        <i class="fa-solid fa-folder-open" />
                      </span>
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
