import { render } from "solid-js/web";
import { MapViewer } from "./MapViewer";

const mountEl = document.getElementById("map-viewer");
if (mountEl) {
  const { ulid, displayName, authorName, authorDisplayName, authorAvatarUrl, updatedAt, viewerName, relativeTimestamps } = mountEl.dataset;
  render(() => <MapViewer
    ulid={ulid!}
    displayName={displayName!}
    authorName={authorName!}
    authorDisplayName={authorDisplayName!}
    authorAvatarUrl={authorAvatarUrl ?? null}
    updatedAt={updatedAt ?? null}
    viewerName={viewerName ?? null}
    relativeTimestamps={relativeTimestamps === "true"}
  />, mountEl);
}
