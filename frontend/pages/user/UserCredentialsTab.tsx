import { createResource, createSignal, For, Show } from "solid-js";
import "../../lib/l10n";
import { SpinnerBlock } from "../../components/SpinnerBlock";
import { ErrorNotification } from "../../components/ErrorNotification";

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
  onSuccess?: () => void;
  onError?: (msgKey: string) => void;
}) => {
  const [data, { refetch }] = createResource(
    () => props.active() && props.userName,
    async (userName) => {
      const res = await fetch(`/api/v1/users/${userName}/credentials`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json() as Promise<CredentialsData>;
    }
  );

  const [disconnecting, setDisconnecting] = createSignal<string | null>(null);

  const handleDisconnect = async (provider: string) => {
    setDisconnecting(provider);
    try {
      const res = await fetch(`/api/v1/users/${props.userName}/credentials/${provider}`, {
        method: "DELETE",
        headers: { "X-CSRF-Token": csrfToken() },
      });
      if (res.ok) {
        refetch();
        props.onSuccess?.();
      } else {
        const json = await res.json() as { error?: string };
        props.onError?.(json.error ?? "error-unknown");
      }
    } finally {
      setDisconnecting(null);
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
                          <button
                            class="button is-danger is-light"
                            type="button"
                            disabled={onlyOne() || disconnecting() === provider}
                            onClick={() => void handleDisconnect(provider)}
                          >
                            <span class="icon"><i class={`fa-brands fa-${provider}`} /></span>
                            <span data-l10n-id={`credential-disconnect-${provider}`} />
                          </button>
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
