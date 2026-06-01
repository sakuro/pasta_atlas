import { Show } from "solid-js";
import { Avatar } from "./Avatar";
import { FormattedDateTime } from "./FormattedDateTime";
import { MapInfoButton } from "./MapInfoButton";
import { ShareButtons } from "./ShareButtons";

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
  const isGuest = () => props.map.user_name === "guest";
  const mapHref = () => `/maps/${props.map.ulid}`;
  const userHref = () => `/@${props.map.user_name}`;

  return (
    <div class="card">
      <Show when={props.map.thumbnail_url}>
        <div class="card-image">
          <figure class="image is-square">
            <a href={mapHref()}>
              <img src={props.map.thumbnail_url!} alt={props.map.display_name} />
            </a>
          </figure>
        </div>
      </Show>
      <div class="card-content">
        <div class="media">
          <div class="media-left">
            {isGuest()
              ? <Avatar url={props.map.author_avatar_url} size={32} />
              : <a href={userHref()}><Avatar url={props.map.author_avatar_url} size={32} /></a>}
          </div>
          <div class="media-content">
            <p class="title is-6">
              <a href={mapHref()}>{props.map.display_name}</a>
            </p>
            <p class="subtitle is-7">
              {isGuest()
                ? props.map.author_display_name
                : <a href={userHref()}>{props.map.author_display_name}</a>}
            </p>
            <Show when={props.map.updated_at}>
              <p class="is-size-7 has-text-grey">
                <FormattedDateTime dateTime={props.map.updated_at!} />
              </p>
            </Show>
          </div>
        </div>
      </div>
      <footer class="card-footer">
        <div class="card-footer-item" style={{ gap: "0.5rem" }}>
          <Show when={props.map.metadata_url}>
            <MapInfoButton metadataUrl={props.map.metadata_url!} />
          </Show>
          <ShareButtons
            mapPath={mapHref()}
            mapName={props.map.display_name}
          />
        </div>
      </footer>
    </div>
  );
};
