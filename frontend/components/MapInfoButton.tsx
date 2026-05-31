import { createSignal, Show } from "solid-js";
import { MapInfoModal, type Mapshot } from "./MapInfoModal";
import "../lib/l10n";

export const MapInfoButton = (props: { metadataUrl: string }) => {
  const [mapshot, setMapshot] = createSignal<Mapshot | null>(null);
  const [show, setShow] = createSignal(false);

  const handleOpen = async () => {
    if (!mapshot()) {
      const data = await fetch(props.metadataUrl).then((r) => r.json() as Promise<Mapshot>);
      setMapshot(data);
    }
    setShow(true);
  };

  return (
    <>
      <a class="button is-small" role="button" onClick={handleOpen} data-l10n-id="map-info-button">
        <span class="icon is-small"><i class="fa-solid fa-circle-info" /></span>
      </a>
      <Show when={show() && mapshot()}>
        <MapInfoModal mapshot={mapshot()!} onClose={() => setShow(false)} />
      </Show>
    </>
  );
};
