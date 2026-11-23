import { createSignal, onSettled, Show } from "solid-js";
import { createAvatarPresignedPost, deleteAvatar } from "../../lib/api/client";
import "../../lib/l10n";
import { Spinner } from "../../components/Spinner";

type I18nError = { msgId: string; msgArgs?: Record<string, string | number> };

type State =
  | { type: "idle" }
  | { type: "selected"; file: File; previewUrl: string }
  | { type: "removing" }
  // previewUrl is kept so the new image stays on screen until the caller has saved it.
  | { type: "uploading"; previewUrl: string | null }
  | { type: "error"; error: I18nError };

const CONTENT_TYPES = ["image/jpeg", "image/png", "image/webp"] as const;
type ContentType = (typeof CONTENT_TYPES)[number];
const isContentType = (type: string): type is ContentType => (CONTENT_TYPES as readonly string[]).includes(type);
const MAX_BYTES = 5 * 1024 * 1024;
const MIN_PX = 64;
const MAX_PX = 1024;

const validateImage = (file: File): Promise<I18nError | null> =>
  new Promise((resolve) => {
    if (!isContentType(file.type)) {
      resolve({ msgId: "avatar-error-unsupported-type" });
      return;
    }
    if (file.size > MAX_BYTES) {
      resolve({ msgId: "avatar-error-too-large-file-size" });
      return;
    }
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      URL.revokeObjectURL(url);
      if (img.width < MIN_PX || img.height < MIN_PX) {
        resolve({ msgId: "avatar-error-too-small-pixel-size", msgArgs: { min: MIN_PX } });
      } else if (img.width > MAX_PX || img.height > MAX_PX) {
        resolve({ msgId: "avatar-error-too-large-pixel-size", msgArgs: { max: MAX_PX } });
      } else {
        resolve(null);
      }
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      resolve({ msgId: "avatar-error-read" });
    };
    img.src = url;
  });

export type AvatarUploadRef = {
  prepareForSubmit: () => Promise<string | null | false>;
  // Called once the caller has saved the result of prepareForSubmit and updated currentAvatarUrl.
  settle: () => void;
};

interface Props {
  currentAvatarUrl: string | null;
  userName: string;
  onRef?: (ref: AvatarUploadRef) => void;
}

export const AvatarUpload = (props: Props) => {
  const [state, setState] = createSignal<State>({ type: "idle" });
  let inputRef!: HTMLInputElement;

  const previewUrl = () => {
    const s = state();
    return s.type === "selected" || s.type === "uploading" ? s.previewUrl : null;
  };
  const errorState = () => {
    const s = state();
    return s.type === "error" ? s : null;
  };

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
      setState({ type: "error", error });
      return;
    }
    setState({ type: "selected", file, previewUrl: URL.createObjectURL(file) });
  };

  onSettled(() => {
    props.onRef?.({
      prepareForSubmit: async () => {
        const s = state();
        if (s.type === "removing") {
          const ok = await removeAvatar();
          return ok ? null : false;
        }
        if (s.type === "selected") {
          const { file, previewUrl } = s;
          const s3Key = await uploadAvatar(file, previewUrl);
          return s3Key ?? false;
        }
        return null;
      },
      settle: () => {
        const s = state();
        if (s.type !== "uploading") return;
        if (s.previewUrl) URL.revokeObjectURL(s.previewUrl);
        setState({ type: "idle" });
      },
    });
  });

  const removeAvatar = async (): Promise<boolean> => {
    setState({ type: "uploading", previewUrl: null });
    const { response } = await deleteAvatar({ path: { user_name: props.userName } });
    if (response?.ok) return true;
    setState({
      type: "error",
      error: response
        ? { msgId: "avatar-error-remove-http", msgArgs: { status: response.status } }
        : { msgId: "avatar-error-network" },
    });
    return false;
  };

  const uploadAvatar = async (file: File, previewUrl: string): Promise<string | null> => {
    setState({ type: "uploading", previewUrl });
    const contentType = file.type;
    if (!isContentType(contentType)) {
      setState({ type: "error", error: { msgId: "avatar-error-unsupported-type" } });
      return null;
    }
    const { data, response } = await createAvatarPresignedPost({
      path: { user_name: props.userName },
      body: { content_type: contentType },
    });
    if (!data) {
      setState({
        type: "error",
        error: response
          ? { msgId: "avatar-error-url-http", msgArgs: { status: response.status } }
          : { msgId: "avatar-error-network" },
      });
      return null;
    }
    const { presigned_post: presignedPost, s3_key: s3Key } = data;
    try {
      // S3 requires the file field to come last; fetch sets the multipart Content-Type itself.
      const form = new FormData();
      for (const [k, v] of Object.entries(presignedPost.fields)) form.append(k, v);
      form.append("file", file);
      const resp = await fetch(presignedPost.url, { method: "POST", body: form });
      if (!resp.ok) {
        setState({ type: "error", error: { msgId: "avatar-error-upload-http", msgArgs: { status: resp.status } } });
        return null;
      }
    } catch {
      setState({ type: "error", error: { msgId: "avatar-error-upload-network" } });
      return null;
    }
    return s3Key;
  };

  const avatarStyle = "border-radius:50%;object-fit:cover";
  const defaultIcon = (
    <i class="fa-solid fa-circle-user" style={{ "font-size": "64px", "line-height": "1", display: "block" }} />
  );

  return (
    <div>
      <input
        ref={(el) => {
          inputRef = el;
        }}
        type="file"
        accept="image/jpeg,image/png,image/webp"
        style={{ display: "none" }}
        onChange={(e) => {
          const file = e.currentTarget.files?.[0];
          if (file) onFileSelected(file);
        }}
      />

      <div style={{ display: "flex", "align-items": "center", gap: "1rem" }}>
        <Show
          when={previewUrl()}
          keyed
          fallback={
            state().type === "removing" || state().type === "uploading" || !props.currentAvatarUrl ? (
              defaultIcon
            ) : (
              <img src={props.currentAvatarUrl} width="64" height="64" style={avatarStyle} />
            )
          }
        >
          {(url) => <img src={url} width="64" height="64" style={avatarStyle} />}
        </Show>

        <div>
          <Show when={state().type === "idle" || state().type === "error"}>
            <button class="button is-small" type="button" onClick={openPicker}>
              <span class="icon">
                <i class="fa-solid fa-image" />
              </span>
              <span data-l10n-id="avatar-change" />
            </button>
            <Show when={props.currentAvatarUrl}>
              <button class="button is-small ml-2" type="button" onClick={() => setState({ type: "removing" })}>
                <span class="icon">
                  <i class="fa-solid fa-trash" />
                </span>
                <span data-l10n-id="avatar-remove" />
              </button>
            </Show>
          </Show>
          <Show when={state().type === "selected" || state().type === "removing"}>
            <button class="button is-small" type="button" onClick={cancel}>
              <span class="icon">
                <i class="fa-solid fa-circle-xmark" />
              </span>
              <span data-l10n-id="avatar-cancel" />
            </button>
          </Show>
          <Show when={state().type === "uploading"}>
            <Spinner />
          </Show>
          {/* No dismiss button: choosing a file or removing the avatar replaces the error. */}
          <Show when={errorState()} keyed>
            {(s) => (
              <p
                class="has-text-danger is-size-7"
                data-l10n-id={s.error.msgId}
                data-l10n-args={s.error.msgArgs ? JSON.stringify(s.error.msgArgs) : undefined}
              />
            )}
          </Show>
        </div>
      </div>
    </div>
  );
};
