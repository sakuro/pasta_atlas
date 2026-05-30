import { createResource, createSignal, onMount, Show } from "solid-js";
import { AvatarUpload } from "../avatar_upload/AvatarUpload";
import "../../l10n";

type ProfileData = {
  user_name: string;
  display_name: string | null;
  avatar_url: string | null;
};

const csrfToken = (): string =>
  document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? "";

export const UserProfileTab = (props: { userName: string; active: () => boolean }) => {
  const [data] = createResource(props.active, async (isActive) => {
    if (!isActive) return undefined;
    const res = await fetch(`/@${props.userName}/profile`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json() as Promise<ProfileData>;
  });

  let formEl!: HTMLFormElement;
  const [formMounted, setFormMounted] = createSignal(false);
  onMount(() => setFormMounted(true));

  return (
    <>
      <Show when={data.loading}>
        <div class="has-text-centered py-5">
          <span class="icon"><i class="fa-solid fa-spinner fa-spin" /></span>
        </div>
      </Show>
      <Show when={data.error}>
        <div class="notification is-danger is-light" data-l10n-id="error-load-failed" />
      </Show>
      <Show when={!data.loading && data()} keyed>
        {(profile) => (
          <form
            ref={formEl}
            action={`/@${props.userName}/profile`}
            method="post"
          >
            <input type="hidden" name="_method" value="patch" />
            <input type="hidden" name="_csrf_token" value={csrfToken()} />
            <input type="hidden" name="user_name" value={props.userName} />
            <div class="field">
              <p class="label">
                <span class="icon-text">
                  <span class="icon"><i class="fa-solid fa-user" /></span>
                  <span data-l10n-id="edit-avatar-label" />
                </span>
              </p>
              <div class="control">
                <Show when={formMounted()}>
                  <AvatarUpload
                    form={formEl}
                    userName={props.userName}
                    currentAvatarUrl={profile.avatar_url}
                  />
                </Show>
              </div>
            </div>
            <div class="field">
              <label class="label" for="display_name">
                <span class="icon-text">
                  <span class="icon"><i class="fa-solid fa-address-card" /></span>
                  <span data-l10n-id="edit-display-name" />
                </span>
              </label>
              <div class="control">
                <input
                  class="input"
                  type="text"
                  id="display_name"
                  name="display_name"
                  value={profile.display_name ?? ""}
                  maxlength="64"
                />
              </div>
            </div>
            <div class="field">
              <div class="control">
                <button class="button is-primary" type="submit">
                  <span class="icon"><i class="fa-solid fa-floppy-disk" /></span>
                  <span data-l10n-id="edit-save-profile" />
                </button>
                <a class="button ml-2" href="/" data-l10n-id="edit-cancel" />
              </div>
            </div>
          </form>
        )}
      </Show>
    </>
  );
};
