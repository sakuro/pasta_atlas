import { render } from "solid-js/web";
import { MapsIndex } from "./MapsIndex";

const mountEl = document.getElementById("maps-index");
if (mountEl) {
  render(() => <MapsIndex />, mountEl);
}
