import { render } from "solid-js/web";
import { MapViewer } from "./MapViewer";

const mountEl = document.getElementById("map-viewer");
if (mountEl) {
  const ulid = mountEl.dataset.ulid!;
  render(() => <MapViewer ulid={ulid} />, mountEl);
}
