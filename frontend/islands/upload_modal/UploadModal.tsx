import { createSignal, Show } from "solid-js";
import { Portal } from "solid-js/web";

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

type State =
  | { type: "idle" }
  | {
      type: "confirming";
      mapshotJson: MapshotJson;
      fileMap: Map<string, File>;
      mapName: string;
      surfaceCount: number;
      imageCount: number;
      totalBytes: number;
    }
  | { type: "uploading"; progress: number; total: number }
  | { type: "done"; viewerUrl: string }
  | { type: "error"; message: string };

const resolveDisplayName = (m: MapshotJson): string => {
  if (m.name) return m.name;
  if (m.savename) return m.savename;
  return m.map_id;
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

export const UploadModal = () => {
  const [state, setState] = createSignal<State>({ type: "idle" });
  let inputRef!: HTMLInputElement;

  const openPicker = () => {
    inputRef.value = "";
    inputRef.click();
  };

  const onFilesSelected = async (files: FileList) => {
    const allFiles = Array.from(files);

    const mapshotFile = allFiles.find((f) => relPath(f) === "mapshot.json");
    if (!mapshotFile) {
      setState({ type: "error", message: "mapshot.json was not found in the selected directory." });
      return;
    }

    let mapshotJson: MapshotJson;
    try {
      mapshotJson = JSON.parse(await mapshotFile.text()) as MapshotJson;
    } catch {
      setState({ type: "error", message: "Failed to parse mapshot.json." });
      return;
    }

    const imageFiles = allFiles.filter((f) => relPath(f) !== "mapshot.json");
    const fileMap = new Map<string, File>();
    for (const f of imageFiles) fileMap.set(relPath(f), f);

    setState({
      type: "confirming",
      mapshotJson,
      fileMap,
      mapName: resolveDisplayName(mapshotJson),
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
    setState({ type: "uploading", progress: 0, total: imageCount });

    // Step 1: POST /api/v1/uploads
    let uploadUlid: string, mapUlid: string, generationUlid: string;
    try {
      const resp = await fetch("/api/v1/uploads", {
        method: "POST",
        headers: jsonHeaders(),
        body: JSON.stringify({ metadata: mapshotJson, total_image_count: imageCount }),
      });
      if (resp.status === 409) {
        setState({ type: "error", message: "This generation has already been uploaded." });
        return;
      }
      if (!resp.ok) {
        setState({ type: "error", message: `Upload failed (HTTP ${resp.status}).` });
        return;
      }
      const data = await resp.json() as { ulid: string; map_ulid: string; generation_ulid: string };
      uploadUlid = data.ulid;
      mapUlid = data.map_ulid;
      generationUlid = data.generation_ulid;
    } catch {
      setState({ type: "error", message: "Network error. Please check your connection and try again." });
      return;
    }

    // Step 2: POST /api/v1/uploads/:ulid/presigned_urls
    const allFilenames = Array.from(fileMap.keys());
    let presignedUrls: Record<string, string>;
    try {
      const resp = await fetch(`/api/v1/uploads/${uploadUlid}/presigned_urls`, {
        method: "POST",
        headers: jsonHeaders(),
        body: JSON.stringify({ filenames: allFilenames }),
      });
      if (!resp.ok) {
        setState({ type: "error", message: `Failed to get upload URLs (HTTP ${resp.status}).` });
        return;
      }
      const data = await resp.json() as { presigned_urls: Record<string, string> };
      presignedUrls = data.presigned_urls;
    } catch {
      setState({ type: "error", message: "Network error getting upload URLs." });
      return;
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
      setState({ type: "error", message: `Failed to upload: ${(err as Error).message}` });
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
        setState({ type: "error", message: "Images uploaded, but finalization failed." });
        return;
      }
    } catch {
      setState({ type: "error", message: "Images uploaded, but network error during finalization." });
      return;
    }

    let viewerUrl = `/maps/${mapUlid}?generation=${generationUlid}`;
    try {
      const resp = await fetch(`/api/v1/maps/${mapUlid}`);
      if (resp.ok) {
        const data = await resp.json() as { owner?: { name?: string } };
        if (data.owner?.name) {
          viewerUrl = `/@${data.owner.name}/maps/${mapUlid}?generation=${generationUlid}`;
        }
      }
    } catch {
      // Use fallback URL without owner path
    }

    setState({ type: "done", viewerUrl });
  };

  const dismiss = () => {
    setState({ type: "idle" });
  };

  const confirmingState = () => {
    const s = state();
    return s.type === "confirming" ? s : null;
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
      <button class="button" onClick={openPicker}>
        <span class="icon"><i class="fa-solid fa-upload"></i></span>
        <span>Upload</span>
      </button>
      <Show when={state().type !== "idle"}>
        <Portal mount={document.body}>
        <div class="modal is-active">
          <div class="modal-background" onClick={dismiss} />
          <div class="modal-card">
            <header class="modal-card-head">
              <p class="modal-card-title">Upload Mapshot</p>
              <Show when={state().type !== "uploading"}>
                <button class="delete" aria-label="close" onClick={dismiss} />
              </Show>
            </header>
            <section class="modal-card-body">
              <Show when={confirmingState()} keyed>
                {(s) => (
                  <table class="table is-fullwidth">
                    <tbody>
                      <tr>
                        <th><span class="icon-text"><span class="icon"><i class="fa-solid fa-map"></i></span><span>Map</span></span></th>
                        <td>{s.mapName}</td>
                      </tr>
                      <tr>
                        <th><span class="icon-text"><span class="icon"><i class="fa-solid fa-layer-group"></i></span><span>Surfaces</span></span></th>
                        <td>{s.surfaceCount}</td>
                      </tr>
                      <tr>
                        <th><span class="icon-text"><span class="icon"><i class="fa-solid fa-images"></i></span><span>Images</span></span></th>
                        <td>{s.imageCount}</td>
                      </tr>
                      <tr>
                        <th><span class="icon-text"><span class="icon"><i class="fa-solid fa-chart-simple"></i></span><span>Total size</span></span></th>
                        <td>{formatBytes(s.totalBytes)}</td>
                      </tr>
                    </tbody>
                  </table>
                )}
              </Show>
              <Show when={uploadingState()} keyed>
                {(s) => (
                  <>
                    <p class="mb-2">
                      Uploading {s.progress} / {s.total} files...
                    </p>
                    <progress class="progress is-primary" value={s.progress} max={s.total} />
                  </>
                )}
              </Show>
              <Show when={doneState()} keyed>
                {(s) => (
                  <div class="has-text-centered">
                    <p class="mb-4">Upload complete!</p>
                    <a href={s.viewerUrl} class="button is-primary">
                      View Map
                    </a>
                  </div>
                )}
              </Show>
              <Show when={errorState()} keyed>
                {(s) => <p class="has-text-danger">{s.message}</p>}
              </Show>
            </section>
            <footer class="modal-card-foot">
              <Show when={state().type === "confirming"}>
                <button class="button is-primary" onClick={startUpload}>
                  <span class="icon"><i class="fa-solid fa-upload"></i></span>
                  <span>Start Upload</span>
                </button>
              </Show>
              <Show when={state().type === "confirming" || state().type === "error"}>
                <button class="button" onClick={dismiss}>
                  <span class="icon"><i class="fa-solid fa-circle-xmark"></i></span>
                  <span>{state().type === "error" ? "Dismiss" : "Cancel"}</span>
                </button>
              </Show>
            </footer>
          </div>
        </div>
        </Portal>
      </Show>
    </>
  );
};
