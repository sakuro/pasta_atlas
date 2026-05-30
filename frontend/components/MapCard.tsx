import { Show } from "solid-js";
import { Avatar } from "./Avatar";
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

export type DateDisplayProps = {
  relativeTimestamps: boolean;
  timezone: string;
};

const lang = () => document.documentElement.lang || "en";

const formatAbsolute = (iso: string, timezone: string): string =>
  new Intl.DateTimeFormat(lang(), {
    year: "numeric", month: "short", day: "numeric",
    hour: "numeric", minute: "numeric",
    timeZone: timezone,
  }).format(new Date(iso));

const formatRelative = (iso: string): string => {
  const diff = Math.round((Date.now() - new Date(iso).getTime()) / 1000);
  const abs = Math.abs(diff);
  const fmt = new Intl.RelativeTimeFormat(lang(), { style: "long", numeric: "auto" });
  if (abs < 60) return fmt.format(-diff, "second");
  if (abs < 3600) return fmt.format(-Math.round(diff / 60), "minute");
  if (abs < 86400) return fmt.format(-Math.round(diff / 3600), "hour");
  if (abs < 7 * 86400) return fmt.format(-Math.round(diff / 86400), "day");
  if (abs < 30 * 86400) return fmt.format(-Math.round(diff / (7 * 86400)), "week");
  if (abs < 365 * 86400) return fmt.format(-Math.round(diff / (30 * 86400)), "month");
  return fmt.format(-Math.round(diff / (365 * 86400)), "year");
};


export const MapCard = (props: { map: MapData } & DateDisplayProps) => {
  const map = props.map;
  const isGuest = map.user_name === "guest";
  const mapHref = `/@${map.user_name}/maps/${map.ulid}`;
  const userHref = `/@${map.user_name}`;

  const displayText = (iso: string) =>
    props.relativeTimestamps ? formatRelative(iso) : formatAbsolute(iso, props.timezone);

  const tooltipText = (iso: string) =>
    props.relativeTimestamps ? formatAbsolute(iso, props.timezone) : formatRelative(iso);

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
                <span class="icon-text">
                  <span class="icon is-small"><i class="fa-regular fa-calendar" /></span>
                  <time datetime={map.updated_at!} title={tooltipText(map.updated_at!)}>
                    {displayText(map.updated_at!)}
                  </time>
                </span>
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
