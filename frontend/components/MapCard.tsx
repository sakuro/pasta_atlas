import { Show } from "solid-js";
import { Avatar } from "./Avatar";
import { FormattedDateTime } from "./FormattedDateTime";
import { MapInfoButton } from "../islands/map_info_button/MapInfoButton";
import { ShareButtons } from "../islands/share_buttons/ShareButtons";

export type MapData = {
  ulid: string;
  display_name: string;
  user_name: string;
  author_display_name: string;
  author_avatar_url: string | null;
  thumbnail_url: string | null;
  metadata_url: string | null;
  updated_at: string | null;
};

export const MapCard = (props: { map: MapData }) => {
  const map = props.map;
  const isGuest = map.user_name === "guest";
  const mapHref = `/@${map.user_name}/maps/${map.ulid}`;
  const userHref = `/@${map.user_name}`;

  return (
    <div class="card">
      <Show when={map.thumbnail_url}>
        <div class="card-image">
          <figure class="image is-square">
            <a href={mapHref}>
              <img src={map.thumbnail_url!} alt={map.display_name} />
            </a>
          </figure>
        </div>
      </Show>
      <div class="card-content">
        <div class="media">
          <div class="media-left">
            {isGuest
              ? <Avatar url={map.author_avatar_url} size={32} />
              : <a href={userHref}><Avatar url={map.author_avatar_url} size={32} /></a>}
          </div>
          <div class="media-content">
            <p class="title is-6">
              <a href={mapHref}>{map.display_name}</a>
            </p>
            <p class="subtitle is-7">
              {isGuest
                ? map.author_display_name
                : <a href={userHref}>{map.author_display_name}</a>}
            </p>
            <Show when={map.updated_at}>
              <p class="is-size-7 has-text-grey">
                <FormattedDateTime dateTime={map.updated_at!} />
              </p>
            </Show>
          </div>
        </div>
      </div>
      <footer class="card-footer">
        <div class="card-footer-item" style="gap:0.5rem">
          <Show when={map.metadata_url}>
            <MapInfoButton metadataUrl={map.metadata_url!} />
          </Show>
          <ShareButtons
            mapPath={mapHref}
            mapName={map.display_name}
          />
        </div>
      </footer>
    </div>
  );
};
