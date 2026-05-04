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

export const formatTicks = (tick: number): string => {
  const totalSeconds = Math.floor(tick / 60);
  const seconds = totalSeconds % 60;
  const totalMinutes = Math.floor(totalSeconds / 60);
  const minutes = totalMinutes % 60;
  const totalHours = Math.floor(totalMinutes / 60);
  const hours = totalHours % 24;
  const days = Math.floor(totalHours / 24);

  if (days > 0) return `${days}d ${hours}h ${minutes}m ${seconds}s`;
  if (hours > 0) return `${hours}h ${minutes}m ${seconds}s`;
  if (minutes > 0) return `${minutes}m ${seconds}s`;
  return `${seconds}s`;
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
      setTimeout(() => setCopied(false), 1500);
    });
  };

  return (
    <button class="button is-small ml-2" onClick={copy} title="Copy">
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
        <div class="modal-background" onClick={props.onClose} />
        <div class="modal-card" style={{ width: "90vw", "max-width": "960px" }}>
          <header class="modal-card-head">
            <p class="modal-card-title">
              <span class="icon-text">
                <span class="icon"><i class="fa-solid fa-circle-info"></i></span>
                <span>Map Info</span>
              </span>
            </p>
            <button class="delete" aria-label="close" onClick={props.onClose} />
          </header>
          <section class="modal-card-body">
            <table class="table is-fullwidth">
              <tbody>
                <Show when={props.mapshot.seed != null}>
                  <tr>
                    <th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-seedling"></i></span><span>Map seed</span></span></th>
                    <td>{props.mapshot.seed}<CopyButton text={String(props.mapshot.seed)} /></td>
                  </tr>
                </Show>
                <Show when={props.mapshot.map_exchange}>
                  <tr>
                    <th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-code"></i></span><span>Map exchange</span></span></th>
                    <td>
                      <button class="button is-small" onClick={() => setShowMapExchange((v) => !v)} title={showMapExchange() ? "Hide" : "Show"}>
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
                    <th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-hourglass"></i></span><span>Tick</span></span></th>
                    <td>{props.mapshot.tick!.toLocaleString()} ({formatTicks(props.mapshot.tick!)})</td>
                  </tr>
                </Show>
                <Show when={props.mapshot.ticks_played != null}>
                  <tr>
                    <th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-hourglass-half"></i></span><span>Ticks played</span></span></th>
                    <td>{props.mapshot.ticks_played!.toLocaleString()} ({formatTicks(props.mapshot.ticks_played!)})</td>
                  </tr>
                </Show>
                <Show when={props.mapshot.game_version}>
                  <tr>
                    <th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-gear"></i></span><span>Game version</span></span></th>
                    <td>{props.mapshot.game_version}</td>
                  </tr>
                </Show>
                <Show when={props.mapshot.active_mods}>
                  <tr>
                    <th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-puzzle-piece"></i></span><span>Mods</span></span></th>
                    <td>
                      <details>
                        <summary>{Object.keys(props.mapshot.active_mods!).length} mods</summary>
                        <ul>
                          <For each={sortedMods(props.mapshot.active_mods!)}>
                            {([name, version]) => <li><a href={`https://mods.factorio.com/mod/${name}`} target="_blank" rel="noopener">{name}</a> {version}</li>}
                          </For>
                        </ul>
                      </details>
                    </td>
                  </tr>
                </Show>
              </tbody>
            </table>
          </section>
          <footer class="modal-card-foot">
            <button class="button" onClick={props.onClose}>
              <span class="icon"><i class="fa-solid fa-circle-xmark"></i></span>
              <span>Close</span>
            </button>
          </footer>
        </div>
      </div>
    </Portal>
  );
};
