import { createMemo, createSignal, Errored, Loading, Show } from "solid-js";
import { AvatarUpload, type AvatarUploadRef } from "./AvatarUpload";
import { errorKey, showProfile, updateProfile } from "../../lib/api/client";
import "../../lib/l10n";
import { SpinnerBlock } from "../../components/SpinnerBlock";
import { ErrorNotification } from "../../components/ErrorNotification";

const segmenter = new Intl.Segmenter();

export type ProfileUpdate = { displayName: string; avatarUrl: string | null };

export const UserProfileTab = (props: {
  userName: string;
  active: () => boolean;
  onSuccess?: (data: ProfileUpdate) => void;
  onError?: (msgKey: string) => void;
}) => {
  const data = createMemo(async () => {
    if (!props.active()) return undefined;
    const { data: profile, error, response } = await showProfile({ path: { user_name: props.userName } });
    if (!profile) throw new Error(`HTTP ${response?.status}`, { cause: error });
    return profile;
  });

  // Editable draft seeded from the fetched profile; re-seeded if the profile is refetched.
  const [displayName, setDisplayName] = createSignal(() => data()?.display_name ?? "");
  const graphemeCount = () => [...segmenter.segment(displayName())].length;
  const [submitting, setSubmitting] = createSignal(false);
  // The fetched profile is not reloaded after a save, so the saved avatar is kept here to keep
  // the form from falling back to the URL it was loaded with. undefined means not saved yet.
  const [savedAvatarUrl, setSavedAvatarUrl] = createSignal<string | null | undefined>(undefined);
  let avatarRef: AvatarUploadRef | undefined;

  const handleSubmit = async (e: SubmitEvent) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const avatarResult = avatarRef ? await avatarRef.prepareForSubmit() : null;
      if (avatarResult === false) return;

      const { data, error } = await updateProfile({
        path: { user_name: props.userName },
        body: {
          display_name: displayName(),
          ...(typeof avatarResult === "string" ? { avatar_s3_key: avatarResult } : {}),
        },
      });
      if (data) {
        setSavedAvatarUrl(data.avatar_url);
        props.onSuccess?.({ displayName: data.display_name, avatarUrl: data.avatar_url });
      } else {
        props.onError?.(errorKey(error) ?? "error-unknown");
      }
    } finally {
      avatarRef?.settle();
      setSubmitting(false);
    }
  };

  return (
    <Errored fallback={<ErrorNotification l10nId="error-load-failed" />}>
      <Loading fallback={<SpinnerBlock />}>
        <Show when={data()} keyed>
          {(profile) => (
            <form onSubmit={(e) => void handleSubmit(e)}>
              <div class="field">
                <p class="label">
                  <span class="icon-text">
                    <span class="icon">
                      <i class="fa-solid fa-user" />
                    </span>
                    <span data-l10n-id="edit-avatar-label" />
                  </span>
                </p>
                <div class="pl-4">
                  <div class="control">
                    <AvatarUpload
                      userName={props.userName}
                      currentAvatarUrl={
                        savedAvatarUrl() === undefined ? profile.avatar_url : (savedAvatarUrl() ?? null)
                      }
                      onRef={(ref) => {
                        avatarRef = ref;
                      }}
                    />
                  </div>
                </div>
              </div>
              <div class="field">
                <label class="label" for="display_name">
                  <span class="icon-text">
                    <span class="icon">
                      <i class="fa-solid fa-address-card" />
                    </span>
                    <span data-l10n-id="edit-display-name" />
                  </span>
                </label>
                <div class="pl-4">
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
                      <span
                        class={["button is-static", graphemeCount() > 30 ? "has-text-danger" : "has-text-grey-light"]}
                      >
                        {graphemeCount()} / 30
                      </span>
                    </div>
                  </div>
                  <p class="help" data-l10n-id="edit-display-name-help" />
                </div>
              </div>
              <div class="field">
                <div class="control">
                  <button class="button is-primary" type="submit" disabled={submitting()}>
                    <span class="icon">
                      <i class="fa-solid fa-floppy-disk" />
                    </span>
                    <span data-l10n-id="edit-save-profile" />
                  </button>
                  <a class="button ml-2" href="/" data-l10n-id="edit-cancel" />
                </div>
              </div>
            </form>
          )}
        </Show>
      </Loading>
    </Errored>
  );
};
