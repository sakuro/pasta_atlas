import { createResource, For, Show } from "solid-js";
import "../../l10n";

type CredentialsData = {
  providers: string[];
  connected_providers: string[];
};

const csrfToken = (): string =>
  document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? "";

export const UserCredentialsTab = (props: {
  userName: string;
  omniauthToken: string;
  active: () => boolean;
}) => {
  const [data] = createResource(props.active, async (isActive) => {
    if (!isActive) return undefined;
    const res = await fetch(`/@${props.userName}/credentials`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json() as Promise<CredentialsData>;
  });

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
        {(creds) => {
          const onlyOne = () => creds.connected_providers.length <= 1;
          return (
            <div class="field">
              <div class="level">
                <div class="level-left">
                  <For each={creds.providers}>
                    {(provider) => (
                      <div class="level-item">
                        <Show
                          when={creds.connected_providers.includes(provider)}
                          fallback={
                            <form action={`/auth/${provider}`} method="post">
                              <input type="hidden" name="authenticity_token" value={props.omniauthToken} />
                              <button class="button" type="submit">
                                <span class="icon"><i class={`fa-brands fa-${provider}`} /></span>
                                <span data-l10n-id={`credential-connect-${provider}`} />
                              </button>
                            </form>
                          }
                        >
                          <form action={`/@${props.userName}/credentials/${provider}`} method="post">
                            <input type="hidden" name="_method" value="delete" />
                            <input type="hidden" name="_csrf_token" value={csrfToken()} />
                            <button
                              class="button is-danger is-light"
                              type="submit"
                              disabled={onlyOne()}
                            >
                              <span class="icon"><i class={`fa-brands fa-${provider}`} /></span>
                              <span data-l10n-id={`credential-disconnect-${provider}`} />
                            </button>
                          </form>
                        </Show>
                      </div>
                    )}
                  </For>
                </div>
              </div>
            </div>
          );
        }}
      </Show>
    </>
  );
};
