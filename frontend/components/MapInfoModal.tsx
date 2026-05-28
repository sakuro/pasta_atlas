import { createSignal, Show, For } from "solid-js";
import { Portal } from "solid-js/web";

export interface Mapshot {
  surfaces?: unknown[];
  game_version?: string;
  active_mods?: Record<string, string>;
  tick?: number;
  ticks_played?: number;
  seed?: number;
  savename?: string;
  map_exchange?: string;
}

export const formatNumber = (n: number): string =>
  new Intl.NumberFormat(document.documentElement.lang || "en").format(n);

export const formatTicks = (tick: number, style: "narrow" | "long" | "short" = "short"): string => {
  const totalSeconds = Math.floor(tick / 60);
  const seconds = totalSeconds % 60;
  const totalMinutes = Math.floor(totalSeconds / 60);
  const minutes = totalMinutes % 60;
  const totalHours = Math.floor(totalMinutes / 60);
  const hours = totalHours % 24;
  const days = Math.floor(totalHours / 24);
  const locale = document.documentElement.lang || "en";
  return new Intl.DurationFormat(locale, { style }).format({ days, hours, minutes, seconds });
};

const PINNED_MODS = ["elevated-rails", "quality", "space-age"];

const sortedMods = (mods: Record<string, string>): [string, string][] => {
  const entries = Object.entries(mods);
  const pinned = PINNED_MODS.flatMap((name) => {
    const entry = entries.find(([n]) => n === name);
    return entry ? [entry] : [];
  });
  const rest = entries
    .filter(([name]) => !PINNED_MODS.includes(name))
    .sort(([a], [b]) => a.toLowerCase().localeCompare(b.toLowerCase()));
  return [...pinned, ...rest];
};

const CopyButton = (props: { text: string }) => {
  const [copied, setCopied] = createSignal(false);

  const copy = () => {
    navigator.clipboard.writeText(props.text).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

  return (
    <button class="button is-small ml-2" onClick={copy} data-l10n-id="map-info-copy">
      <span class="icon is-small">
        <i class={copied() ? "fa-solid fa-check" : "fa-solid fa-copy"} />
      </span>
    </button>
  );
};

export const MapInfoModal = (props: { mapshot: Mapshot; onClose: () => void }) => {
  const [showMapExchange, setShowMapExchange] = createSignal(false);

  return (
    <Portal mount={document.body}>
      <div class="modal is-active">
        <div class="modal-background" onClick={() => props.onClose()} />
        <div class="modal-card" style={{ width: "90vw", "max-width": "960px" }}>
          <header class="modal-card-head">
            <p class="modal-card-title">
              <span class="icon-text">
                <span class="icon"><i class="fa-solid fa-circle-info" /></span>
                <span data-l10n-id="map-info-title" />
              </span>
            </p>
            <button class="delete" aria-label="close" onClick={() => props.onClose()} />
          </header>
          <section class="modal-card-body">
            <table class="table is-fullwidth">
              <tbody>
                <Show when={props.mapshot.seed != null}>
                  <tr>
                    <th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-seedling" /></span><span data-l10n-id="map-info-seed" /></span></th>
                    <td>{props.mapshot.seed}<CopyButton text={String(props.mapshot.seed)} /></td>
                  </tr>
                </Show>
                <Show when={props.mapshot.map_exchange}>
                  <tr>
                    <th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-code" /></span><span data-l10n-id="map-info-exchange" /></span></th>
                    <td>
                      <button
                        class="button is-small"
                        onClick={() => setShowMapExchange((v) => !v)}
                        data-l10n-id={showMapExchange() ? "map-info-exchange-hide" : "map-info-exchange-show"}
                      >
                        <span class="icon is-small"><i class={showMapExchange() ? "fa-solid fa-eye-slash" : "fa-solid fa-eye"} /></span>
                      </button>
                      <CopyButton text={props.mapshot.map_exchange!} />
                      <Show when={showMapExchange()}>
                        <pre style={{ "white-space": "pre-wrap", "word-break": "break-all" }}>{props.mapshot.map_exchange}</pre>
                      </Show>
                    </td>
                  </tr>
                </Show>
                <Show when={props.mapshot.tick != null}>
                  <tr>
                    <th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-hourglass" /></span><span data-l10n-id="map-info-tick" /><span class="icon is-small has-text-grey-light" data-l10n-id="map-info-tick-help"><i class="fa-regular fa-circle-question" /></span></span></th>
                    <td>{formatNumber(props.mapshot.tick!)} ({formatTicks(props.mapshot.tick!, "long")})</td>
                  </tr>
                </Show>
                <Show when={props.mapshot.ticks_played != null}>
                  <tr>
                    <th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-hourglass-half" /></span><span data-l10n-id="map-info-ticks-played" /><span class="icon is-small has-text-grey-light" data-l10n-id="map-info-ticks-played-help"><i class="fa-regular fa-circle-question" /></span></span></th>
                    <td>{formatNumber(props.mapshot.ticks_played!)} ({formatTicks(props.mapshot.ticks_played!, "long")})</td>
                  </tr>
                </Show>
                <Show when={props.mapshot.game_version}>
                  <tr>
                    <th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-gear" /></span><span data-l10n-id="map-info-game-version" /></span></th>
                    <td>{props.mapshot.game_version}</td>
                  </tr>
                </Show>
                <Show when={props.mapshot.active_mods}>
                  <tr>
                    <th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-puzzle-piece" /></span><span data-l10n-id="map-info-mods" /></span></th>
                    <td>
                      <details>
                        <summary
                          data-l10n-id="map-info-mods-count"
                          data-l10n-args={JSON.stringify({ count: Object.keys(props.mapshot.active_mods!).length })}
                        />
                        <div style={{ "overflow-y": "auto", "max-height": "300px" }}>
                          <table class="table is-narrow is-fullwidth">
                            <tbody>
                              <For each={sortedMods(props.mapshot.active_mods!)}>
                                {([name, version]) => (
                                  <tr>
                                    <td><a href={`https://mods.factorio.com/mod/${name}`} target="_blank" rel="noopener">{name}</a></td>
                                    <td>{version}</td>
                                  </tr>
                                )}
                              </For>
                            </tbody>
                          </table>
                        </div>
                      </details>
                    </td>
                  </tr>
                </Show>
              </tbody>
            </table>
          </section>
          <footer class="modal-card-foot">
            <button class="button" onClick={() => props.onClose()}>
              <span class="icon"><i class="fa-solid fa-circle-xmark" /></span>
              <span data-l10n-id="map-info-close" />
            </button>
          </footer>
        </div>
      </div>
    </Portal>
  );
};
