import { createResource, Show } from "solid-js";
import { useParams } from "@solidjs/router";
import { useAuth } from "../contexts/AuthContext";
import { MapViewer } from "./map_viewer/MapViewer";

interface MapViewerData {
  ulid: string;
  display_name: string;
  owner: {
    name: string;
    display_name: string;
    avatar_url: string | null;
  };
  updated_at: string | null;
}

export const MapViewerPage = () => {
  const params = useParams();
  const { currentUser } = useAuth();

  const [data] = createResource(
    () => ({ userName: (params.at_user_name ?? "").slice(1), ulid: params.ulid }),
    async ({ userName, ulid }) => {
      const res = await fetch(`/api/v1/users/${userName}/maps/${ulid}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      return res.json() as Promise<MapViewerData>;
    }
  );

  const viewerName = () => {
    const user = currentUser();
    return user ? user.name : null;
  };

  return (
    <div class="map-viewer-page">
      <Show when={data.loading}>
        <div class="has-text-centered py-5">
          <span class="icon"><i class="fa-solid fa-spinner fa-spin" /></span>
        </div>
      </Show>
      <Show when={data.error}>
        <div class="notification is-danger is-light" data-l10n-id="error-load-failed" />
      </Show>
      <Show when={!data.error && data()} keyed>
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
    </div>
  );
};
