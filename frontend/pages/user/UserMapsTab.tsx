import { createMemo, Errored, For, Loading, Show } from "solid-js";
import { MapCard } from "../../components/MapCard";
import { listRecentMapsOfUser } from "../../lib/api/client";
import "../../lib/l10n";
import { SpinnerBlock } from "../../components/SpinnerBlock";
import { ErrorNotification } from "../../components/ErrorNotification";

export const UserMapsTab = (props: { userName: string; active: () => boolean }) => {
  const data = createMemo(async () => {
    if (!props.active()) return undefined;
    const { data: body, error, response } = await listRecentMapsOfUser({ path: { user_name: props.userName } });
    if (!body) throw new Error(`HTTP ${response?.status}`, { cause: error });
    return body;
  });

  return (
    <Errored fallback={<ErrorNotification l10nId="error-load-failed" />}>
      <Loading fallback={<SpinnerBlock />}>
        <Show when={data()} keyed>
          {(response) => (
            <div class="columns is-multiline">
              <For each={response.maps}>
                {(map) => (
                  <div class="column is-half-tablet is-one-quarter-desktop">
                    <MapCard map={map} />
                  </div>
                )}
              </For>
            </div>
          )}
        </Show>
      </Loading>
    </Errored>
  );
};
