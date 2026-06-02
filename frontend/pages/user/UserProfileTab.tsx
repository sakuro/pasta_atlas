import { createResource, createSignal, Show } from "solid-js";
import { AvatarUpload, type AvatarUploadRef } from "./AvatarUpload";
import "../../lib/l10n";
import { SpinnerBlock } from "../../components/SpinnerBlock";
import { ErrorNotification } from "../../components/ErrorNotification";

const segmenter = new Intl.Segmenter();

type ProfileData = {
  user_name: string;
  display_name: string | null;
  avatar_url: string | null;
};

const csrfToken = (): string =>
  document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? "";

export type ProfileUpdate = { displayName: string; avatarUrl: string | null };

export const UserProfileTab = (props: {
  userName: string;
  active: () => boolean;
  onSuccess?: (data: ProfileUpdate) => void;
  onError?: (msgKey: string) => void;
}) => {
  const [data] = createResource(
    () => props.active() && props.userName,
    async (userName) => {
      const res = await fetch(`/api/v1/users/${userName}/profile`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json() as Promise<ProfileData>;
    }
  );

  const [displayName, setDisplayName] = createSignal("");
  const graphemeCount = () => [...segmenter.segment(displayName())].length;
  const [submitting, setSubmitting] = createSignal(false);
  let avatarRef: AvatarUploadRef | undefined;

  const handleSubmit = async (e: SubmitEvent) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const avatarResult = avatarRef ? await avatarRef.prepareForSubmit() : null;
      if (avatarResult === false) return;

      const body: Record<string, string | null> = {
        user_name: props.userName,
        display_name: displayName(),
      };
      if (typeof avatarResult === "string") body.avatar_s3_key = avatarResult;

      const res = await fetch(`/api/v1/users/${props.userName}/profile`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        body: JSON.stringify(body),
      });
      if (res.ok) {
        const data = await res.json() as { display_name: string; avatar_url: string | null };
        props.onSuccess?.({ displayName: data.display_name, avatarUrl: data.avatar_url });
      } else {
        const json = await res.json() as { error?: string };
        props.onError?.(json.error ?? "error-unknown");
      }
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <>
      <Show when={data.loading}>
        <SpinnerBlock />
      </Show>
      <Show when={data.error}>
        <ErrorNotification l10nId="error-load-failed" />
      </Show>
      <Show when={!data.loading && data()} keyed>
        {(profile) => {
          setDisplayName(profile.display_name ?? "");
          return (
            <form onSubmit={(e) => void handleSubmit(e)}>
              <div class="field">
                <p class="label">
                  <span class="icon-text">
                    <span class="icon"><i class="fa-solid fa-user" /></span>
                    <span data-l10n-id="edit-avatar-label" />
                  </span>
                </p>
                <div class="control">
                  <AvatarUpload
                    userName={props.userName}
                    currentAvatarUrl={profile.avatar_url}
                    onRef={(ref) => { avatarRef = ref; }}
                  />
                </div>
              </div>
              <div class="field">
                <label class="label" for="display_name">
                  <span class="icon-text">
                    <span class="icon"><i class="fa-solid fa-address-card" /></span>
                    <span data-l10n-id="edit-display-name" />
                  </span>
                </label>
                <div class="field has-addons mb-0">
                  <div class="control is-expanded">
                    <input
                      class="input"
                      type="text"
                      id="display_name"
                      name="display_name"
                      value={displayName()}
                      onInput={(e) => setDisplayName(e.currentTarget.value)}
                    />
                  </div>
                  <div class="control">
                    <span class={`button is-static ${graphemeCount() > 30 ? "has-text-danger" : "has-text-grey-light"}`}>
                      {graphemeCount()} / 30
                    </span>
                  </div>
                </div>
                <p class="help" data-l10n-id="edit-display-name-help" />
              </div>
              <div class="field">
                <div class="control">
                  <button class="button is-primary" type="submit" disabled={submitting()}>
                    <span class="icon"><i class="fa-solid fa-floppy-disk" /></span>
                    <span data-l10n-id="edit-save-profile" />
                  </button>
                  <a class="button ml-2" href="/" data-l10n-id="edit-cancel" />
                </div>
              </div>
            </form>
          );
        }}
      </Show>
    </>
  );
};
