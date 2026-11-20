import { createMemo, Errored, For, Loading, Show } from "solid-js";
import { MapCard, type MapData } from "../../components/MapCard";
import "../../lib/l10n";
import { SpinnerBlock } from "../../components/SpinnerBlock";
import { ErrorNotification } from "../../components/ErrorNotification";

type MapsResponse = { maps: MapData[] };

export const UserMapsTab = (props: { userName: string; active: () => boolean }) => {
  const data = createMemo(async (): Promise<MapsResponse | undefined> => {
    if (!props.active()) return undefined;
    const res = await fetch(`/api/v1/users/${props.userName}/maps`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json() as Promise<MapsResponse>;
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
