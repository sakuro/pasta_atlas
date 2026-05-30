import { createResource, For, Show } from "solid-js";
import { MapInfoButton } from "../map_info_button/MapInfoButton";
import { ShareButtons } from "../share_buttons/ShareButtons";
import "../../l10n";

type MapData = {
  ulid: string;
  display_name: string;
  user_name: string;
  author_display_name: string;
  author_avatar_url: string | null;
  thumbnail_url: string | null;
  metadata_url: string | null;
  updated_at: string | null;
};

type MapsResponse = { maps: MapData[] };

const formatDate = (iso: string): string =>
  new Intl.DateTimeFormat(document.documentElement.lang || "en", {
    year: "numeric", month: "short", day: "numeric",
  }).format(new Date(iso));

const UserAvatar = (props: { url: string | null; size: number; href: string }) => (
  <a href={props.href}>
    {props.url
      ? <img src={props.url} width={props.size} height={props.size} style="border-radius:50%" />
      : <i class="fa-solid fa-circle-user" style={`font-size:${props.size}px`} />}
  </a>
);

export const UserMapsTab = (props: { userName: string; active: () => boolean }) => {
  const [data] = createResource(props.active, async (isActive) => {
    if (!isActive) return undefined;
    const res = await fetch(`/@${props.userName}/maps`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json() as Promise<MapsResponse>;
  });

  return (
    <>
      <Show when={data.loading}>
        <div class="has-text-centered py-5">
          <span class="icon"><i class="fa-solid fa-spinner fa-spin" /></span>
        </div>
      </Show>
      <Show when={data.error}>
        <div class="notification is-danger is-light" data-l10n-id="error-load-failed" />
      </Show>
      <Show when={data()} keyed>
        {(response) => (
          <div class="columns is-multiline">
            <For each={response.maps}>
              {(map) => (
                <div class="column is-half-tablet is-one-quarter-desktop">
                  <div class="card">
                    <Show when={map.thumbnail_url}>
                      <div class="card-image">
                        <figure class="image is-square">
                          <a href={`/@${map.user_name}/maps/${map.ulid}`}>
                            <img src={map.thumbnail_url!} alt={map.display_name} />
                          </a>
                        </figure>
                      </div>
                    </Show>
                    <div class="card-content">
                      <div class="media">
                        <div class="media-left">
                          <UserAvatar url={map.author_avatar_url} size={32} href={`/@${map.user_name}`} />
                        </div>
                        <div class="media-content">
                          <p class="title is-6">
                            <a href={`/@${map.user_name}/maps/${map.ulid}`}>{map.display_name}</a>
                          </p>
                          <p class="subtitle is-7">
                            <a href={`/@${map.user_name}`}>{map.author_display_name}</a>
                          </p>
                          <Show when={map.updated_at}>
                            <p class="is-size-7 has-text-grey">
                              <span class="icon-text">
                                <span class="icon is-small"><i class="fa-regular fa-calendar" /></span>
                                <time datetime={map.updated_at!}>{formatDate(map.updated_at!)}</time>
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
                          mapPath={`/@${map.user_name}/maps/${map.ulid}`}
                          mapName={map.display_name}
                        />
                      </div>
                    </footer>
                  </div>
                </div>
              )}
            </For>
          </div>
        )}
      </Show>
    </>
  );
};
