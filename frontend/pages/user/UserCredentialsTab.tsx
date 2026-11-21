import { affects, createMemo, createSignal, Errored, For, isPending, Loading, refresh, Show } from "solid-js";
import "../../lib/l10n";
import { SpinnerBlock } from "../../components/SpinnerBlock";
import { ErrorNotification } from "../../components/ErrorNotification";

type CredentialsData = {
  providers: string[];
  connected_providers: string[];
};

const csrfToken = (): string => document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? "";

export const UserCredentialsTab = (props: {
  userName: string;
  omniauthToken: string;
  active: () => boolean;
  onSuccess?: () => void;
  onError?: (msgKey: string) => void;
}) => {
  const data = createMemo(async (): Promise<CredentialsData | undefined> => {
    if (!props.active()) return undefined;
    const res = await fetch(`/api/v1/users/${props.userName}/credentials`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json() as Promise<CredentialsData>;
  });

  const [disconnecting, setDisconnecting] = createSignal<string | null>(null);

  const handleDisconnect = async (provider: string) => {
    setDisconnecting(provider);
    try {
      const res = await fetch(`/api/v1/users/${props.userName}/credentials/${provider}`, {
        method: "DELETE",
        headers: { "X-CSRF-Token": csrfToken() },
      });
      if (res.ok) {
        // affects() makes the reload read as pending, so the list is replaced by the spinner
        // until the fresh credentials arrive (a bare refresh() would swap them in silently).
        affects(data);
        void refresh(data);
        props.onSuccess?.();
      } else {
        const json = (await res.json()) as { error?: string };
        props.onError?.(json.error ?? "error-unknown");
      }
    } finally {
      setDisconnecting(null);
    }
  };

  return (
    <Errored fallback={<ErrorNotification l10nId="error-load-failed" />}>
      <Loading fallback={<SpinnerBlock />}>
        <Show when={!isPending(() => data())} fallback={<SpinnerBlock />}>
          <Show when={data()} keyed>
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
                                    <span class="icon">
                                      <i class={`fa-brands fa-${provider}`} />
                                    </span>
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
                                <span class="icon">
                                  <i class={`fa-brands fa-${provider}`} />
                                </span>
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
        </Show>
      </Loading>
    </Errored>
  );
};
