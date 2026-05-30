import { createResource, For, Show } from "solid-js";
import { MapCard, type MapData } from "../../components/MapCard";
import "../../l10n";

type MapsResponse = { maps: MapData[] };

export const UserMapsTab = (props: { userName: string; active: () => boolean }) => {
  const [data] = createResource(props.active, async (isActive) => {
    if (!isActive) return undefined;
    const res = await fetch(`/@${props.userName}/maps`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json() as Promise<MapsResponse>;
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
    </>
  );
};
