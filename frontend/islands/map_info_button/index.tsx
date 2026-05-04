import { render } from "solid-js/web";
import { MapInfoButton } from "./MapInfoButton";

document.querySelectorAll<HTMLElement>(".map-info-button-mount").forEach((el) => {
  const metadataUrl = el.dataset.metadataUrl;
  if (metadataUrl) {
    render(() => <MapInfoButton metadataUrl={metadataUrl} />, el);
  }
});
