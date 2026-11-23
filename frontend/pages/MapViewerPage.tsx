import { createMemo, Errored, Loading, Show } from "solid-js";
import { useParams } from "@solidjs/router";
import { useAuth } from "../contexts/AuthContext";
import { MapViewer } from "./map_viewer/MapViewer";
import { SpinnerBlock } from "../components/SpinnerBlock";
import { ErrorNotification } from "../components/ErrorNotification";
import { showMap } from "../lib/api/client";

class NotFoundError extends Error {}

export const MapViewerPage = () => {
  const params = useParams<{ ulid: string }>();
  const { currentUser } = useAuth();

  const data = createMemo(async () => {
    const { data: map, error, response } = await showMap({ path: { ulid: params.ulid } });
    if (response?.status === 404) throw new NotFoundError();
    if (!map) throw new Error(`HTTP ${response?.status}`, { cause: error });
    return map;
  });

  const viewerName = () => {
    const user = currentUser();
    return user ? user.name : null;
  };

  return (
    <div class="map-viewer-page">
      <Errored
        fallback={(err) => (
          <Show when={err() instanceof NotFoundError} fallback={<ErrorNotification l10nId="error-load-failed" />}>
            <ErrorNotification l10nId="error-map-not-found" type="warning" />
          </Show>
        )}
      >
        <Loading fallback={<SpinnerBlock />} on={params.ulid}>
          <Show when={data()} keyed>
            {(mapData) => (
              <div id="map-viewer">
                <MapViewer
                  ulid={mapData.ulid}
                  displayName={mapData.display_name}
                  authorName={mapData.owner.name}
                  authorDisplayName={mapData.owner.display_name}
                  authorAvatarUrl={mapData.owner.avatar_url}
                  updatedAt={mapData.updated_at}
                  viewerName={viewerName()}
                />
              </div>
            )}
          </Show>
        </Loading>
      </Errored>
    </div>
  );
};
