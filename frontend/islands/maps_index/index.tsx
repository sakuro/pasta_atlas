import { render } from "solid-js/web";
import { MapsIndex } from "./MapsIndex";

const mountEl = document.getElementById("maps-index");
if (mountEl) {
  const relativeTimestamps = mountEl.dataset.relativeTimestamps === "true";
  const timezone = mountEl.dataset.viewerTimezone ?? "UTC";
  render(() => <MapsIndex relativeTimestamps={relativeTimestamps} timezone={timezone} />, mountEl);
}
