import { createSignal, onMount, onCleanup, Show } from "solid-js";

const csrfToken = (): string =>
  document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? "";

const jsonHeaders = (): HeadersInit => ({
  "Content-Type": "application/json",
  "X-CSRF-Token": csrfToken(),
});

type State =
  | { type: "idle" }
  | { type: "selected"; file: File; previewUrl: string }
  | { type: "removing" }
  | { type: "uploading" }
  | { type: "error"; message: string };

const MAX_BYTES = 5 * 1024 * 1024;
const MIN_PX = 64;
const MAX_PX = 1024;

const validateImage = (file: File): Promise<string | null> =>
  new Promise((resolve) => {
    if (file.size > MAX_BYTES) {
      resolve("File must be 5 MB or smaller.");
      return;
    }
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      URL.revokeObjectURL(url);
      if (img.width < MIN_PX || img.height < MIN_PX) {
        resolve(`Image must be at least ${MIN_PX}×${MIN_PX}.`);
      } else if (img.width > MAX_PX || img.height > MAX_PX) {
        resolve(`Image must be ${MAX_PX}×${MAX_PX} or smaller.`);
      } else {
        resolve(null);
      }
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      resolve("Failed to read image.");
    };
    img.src = url;
  });

interface Props {
  currentAvatarUrl: string | null;
  userName: string;
  form: HTMLFormElement | null;
}

export const AvatarUpload = (props: Props) => {
  const [state, setState] = createSignal<State>({ type: "idle" });
  let inputRef!: HTMLInputElement;

  const selectedState = () => { const s = state(); return s.type === "selected" ? s : null; };
  const errorState = () => { const s = state(); return s.type === "error" ? s : null; };

  const openPicker = () => {
    inputRef.value = "";
    inputRef.click();
  };

  const cancel = () => {
    const s = state();
    if (s.type === "selected") URL.revokeObjectURL(s.previewUrl);
    setState({ type: "idle" });
  };

  const onFileSelected = async (file: File) => {
    const error = await validateImage(file);
    if (error) {
      setState({ type: "error", message: error });
      return;
    }
    setState({ type: "selected", file, previewUrl: URL.createObjectURL(file) });
  };

  onMount(() => {
    if (!props.form) return;
    const handler = (e: SubmitEvent) => { void handleFormSubmit(e); };
    props.form.addEventListener("submit", handler);
    onCleanup(() => props.form?.removeEventListener("submit", handler));
  });

  const handleFormSubmit = async (e: SubmitEvent) => {
    const s = state();

    if (s.type === "removing") {
      e.preventDefault();
      setState({ type: "uploading" });
      try {
        const resp = await fetch(`/@${props.userName}/profile/avatar`, {
          method: "DELETE",
          headers: { "X-CSRF-Token": csrfToken() },
        });
        if (!resp.ok) {
          setState({ type: "error", message: `Failed to remove avatar (HTTP ${resp.status}).` });
          return;
        }
      } catch {
        setState({ type: "error", message: "Network error. Please try again." });
        return;
      }
      props.form!.submit();
      return;
    }

    if (s.type !== "selected") return;

    e.preventDefault();
    const { file, previewUrl } = s;
    setState({ type: "uploading" });

    let presignedUrl: string, s3Key: string;
    try {
      const resp = await fetch("/api/v1/profile/avatar_presigned_url", {
        method: "POST",
        headers: jsonHeaders(),
        body: JSON.stringify({ content_type: file.type }),
      });
      if (!resp.ok) {
        setState({ type: "error", message: `Failed to get upload URL (HTTP ${resp.status}).` });
        return;
      }
      const data = await resp.json() as { presigned_url: string; s3_key: string };
      presignedUrl = data.presigned_url;
      s3Key = data.s3_key;
    } catch {
      setState({ type: "error", message: "Network error. Please try again." });
      return;
    }

    try {
      const resp = await fetch(presignedUrl, {
        method: "PUT",
        headers: { "Content-Type": file.type },
        body: file,
      });
      if (!resp.ok) {
        setState({ type: "error", message: `Upload failed (HTTP ${resp.status}).` });
        return;
      }
    } catch {
      setState({ type: "error", message: "Network error during upload." });
      return;
    }

    URL.revokeObjectURL(previewUrl);

    const existing = props.form!.querySelector<HTMLInputElement>('input[name="avatar_s3_key"]');
    if (existing) existing.remove();
    const hidden = document.createElement("input");
    hidden.type = "hidden";
    hidden.name = "avatar_s3_key";
    hidden.value = s3Key;
    props.form!.appendChild(hidden);

    props.form!.submit();
  };

  const avatarStyle = "border-radius:50%;object-fit:cover";
  const defaultIcon = <i class="fa-solid fa-circle-user" style="font-size:64px;line-height:1;display:block"></i>;

  return (
    <div>
      <input
        ref={(el) => { inputRef = el; }}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        style={{ display: "none" }}
        onChange={(e) => {
          const file = e.currentTarget.files?.[0];
          if (file) onFileSelected(file);
        }}
      />

      <div style={{ display: "flex", "align-items": "center", gap: "1rem" }}>
        <Show when={selectedState()} keyed fallback={
          state().type === "removing" || !props.currentAvatarUrl
            ? defaultIcon
            : <img src={props.currentAvatarUrl} width="64" height="64" style={avatarStyle} />
        }>
          {(s) => <img src={s.previewUrl} width="64" height="64" style={avatarStyle} />}
        </Show>

        <div>
          <Show when={state().type === "idle" || state().type === "error"}>
            <button class="button is-small" type="button" onClick={openPicker}>
              <span class="icon"><i class="fa-solid fa-image"></i></span>
              <span>Change</span>
            </button>
            <Show when={props.currentAvatarUrl}>
              <button class="button is-small ml-2" type="button" onClick={() => setState({ type: "removing" })}>
                <span class="icon"><i class="fa-solid fa-trash"></i></span>
                <span>Remove</span>
              </button>
            </Show>
          </Show>
          <Show when={state().type === "selected" || state().type === "removing"}>
            <button class="button is-small" type="button" onClick={cancel}>
              <span class="icon"><i class="fa-solid fa-circle-xmark"></i></span>
              <span>Cancel</span>
            </button>
          </Show>
          <Show when={state().type === "uploading"}>
            <span class="icon"><i class="fa-solid fa-spinner fa-spin"></i></span>
          </Show>
          <Show when={errorState()} keyed>
            {(s) => (
              <div>
                <p class="has-text-danger is-size-7">{s.message}</p>
                <button class="button is-small mt-1" type="button" onClick={cancel}>Dismiss</button>
              </div>
            )}
          </Show>
        </div>
      </div>
    </div>
  );
};
