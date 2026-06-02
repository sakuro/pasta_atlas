import { createResource, For, Show } from "solid-js";
import { MapCard, type MapData } from "../../components/MapCard";
import "../../lib/l10n";
import { SpinnerBlock } from "../../components/SpinnerBlock";
import { ErrorNotification } from "../../components/ErrorNotification";

type MapsResponse = { maps: MapData[] };

export const UserMapsTab = (props: { userName: string; active: () => boolean }) => {
  const [data] = createResource(
    () => props.active() && props.userName,
    async (userName) => {
      const res = await fetch(`/api/v1/users/${userName}/maps`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json() as Promise<MapsResponse>;
    }
  );

  return (
    <>
      <Show when={data.loading}>
        <SpinnerBlock />
      </Show>
      <Show when={data.error}>
        <ErrorNotification l10nId="error-load-failed" />
      </Show>
      <Show when={!data.error && data()} keyed>
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
    </>
  );
};
