import { render } from "solid-js/web";
import { ShareButtons } from "./ShareButtons";

document.querySelectorAll<HTMLElement>(".share-buttons-mount").forEach((el) => {
  const mapPath = el.dataset.mapPath;
  const mapName = el.dataset.mapName ?? "";
  if (mapPath) {
    render(() => <ShareButtons mapPath={mapPath} mapName={mapName} />, el);
  }
});
