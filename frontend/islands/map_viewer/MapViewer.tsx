import { createResource, createSignal, createMemo, Show, Suspense, For, onMount, onCleanup } from "solid-js";
import { Portal } from "solid-js/web";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import "leaflet.zoomslider";
import "leaflet-control-boxzoom";
import zoomsliderCss from "leaflet.zoomslider/src/L.Control.Zoomslider.css?raw";
import boxzoomCss from "leaflet-control-boxzoom/dist/leaflet-control-boxzoom.css?raw";

const pluginStyle = document.createElement("style");
pluginStyle.textContent = zoomsliderCss + boxzoomCss +
  `.leaflet-control-zoomslider-body,.leaflet-control-zoomslider-knob{box-sizing:content-box!important}` +
  `.leaflet-control-boxzoom{display:flex!important;align-items:center!important;justify-content:center!important;width:26px!important;height:26px!important;line-height:26px!important;box-sizing:content-box!important}` +
  `.leaflet-touch .leaflet-control-boxzoom{width:30px!important;height:30px!important;line-height:30px!important}` +
  `.leaflet-control-boxzoom i{font-size:18px}`;
document.head.appendChild(pluginStyle);
import markerIcon from "leaflet/dist/images/marker-icon.png";
import markerIcon2x from "leaflet/dist/images/marker-icon-2x.png";
import markerShadow from "leaflet/dist/images/marker-shadow.png";

// Vite breaks Leaflet's runtime URL resolution for default marker images
delete (L.Icon.Default.prototype as unknown as Record<string, unknown>)["_getIconUrl"];
L.Icon.Default.mergeOptions({ iconUrl: markerIcon, iconRetinaUrl: markerIcon2x, shadowUrl: markerShadow });

interface Generation {
  ulid: string;
  tick: number;
  metadata_url: string;
}

interface Station {
  backer_name: string;
  bounding_box: {
    left_top: { x: number; y: number };
    right_bottom: { x: number; y: number };
  };
}

interface Tag {
  text: string;
  position: { x: number; y: number };
}

interface Surface {
  surface_idx: number;
  surface_localised_name: string;
  surface_name: string;
  is_planet: boolean;
  file_prefix: string;
  tile_size: number;
  render_size: number;
  world_min: { x: number; y: number };
  world_max: { x: number; y: number };
  zoom_min: number;
  zoom_max: number;
  stations?: Station[];
  tags?: Record<string, Tag>;
}

interface Mapshot {
  surfaces: Surface[];
  game_version?: string;
  active_mods?: Record<string, string>;
  tick?: number;
  ticks_played?: number;
  seed?: number;
  savename?: string;
  map_exchange?: string;
}

interface MapData {
  generations: Generation[];
}

const formatTicks = (tick: number): string => {
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

const getParam = (key: string): string | null =>
  new URLSearchParams(window.location.search).get(key);

const setParams = (updates: Record<string, string | null>) => {
  const params = new URLSearchParams(window.location.search);
  for (const [key, value] of Object.entries(updates)) {
    if (value === null) params.delete(key);
    else params.set(key, value);
  }
  history.replaceState(null, "", `?${params}`);
};

export const MapViewer = (props: { ulid: string }) => {
  const [mapData] = createResource(() =>
    fetch(`/api/v1/maps/${props.ulid}`).then((r) => r.json() as Promise<MapData>)
  );

  const [generationUlid, setGenerationUlid] = createSignal<string | null>(
    getParam("generation")
  );

  const activeGeneration = createMemo(() => {
    const data = mapData();
    if (!data?.generations.length) return undefined;
    const ulid = generationUlid();
    return ulid
      ? (data.generations.find((g) => g.ulid === ulid) ?? data.generations[0])
      : data.generations[0];
  });

  const [mapshot] = createResource(
    () => activeGeneration()?.metadata_url,
    (url) => fetch(url).then((r) => r.json() as Promise<Mapshot>)
  );

  const activeMapData = createMemo(() => {
    const ms = mapshot();
    const gen = activeGeneration();
    if (!ms || !gen) return null;
    return { mapshot: ms, assetBase: gen.metadata_url.replace(/mapshot\.json$/, "") };
  });

  const [showInfo, setShowInfo] = createSignal(false);
  const [showMapExchange, setShowMapExchange] = createSignal(false);

  const closeInfo = () => {
    setShowInfo(false);
    setShowMapExchange(false);
  };

  const handleGenerationChange = (ulid: string) => {
    setGenerationUlid(ulid);
    setParams({ generation: ulid, s: null, x: null, y: null, z: null });
  };

  return (
    <div style={{ display: "flex", "flex-direction": "column", height: "100%" }}>
      <Show when={mapData()}>
        {(data) => (
          <div style={{ padding: "0.5rem", "flex-shrink": 0, display: "flex", gap: "0.5rem", "align-items": "center" }}>
            <div class="control has-icons-left">
              <div class="select is-small">
                <select
                  value={activeGeneration()?.ulid ?? ""}
                  onChange={(e) => handleGenerationChange(e.currentTarget.value)}
                >
                  <For each={data().generations}>
                    {(gen) => (
                      <option value={gen.ulid}>{formatTicks(gen.tick)}</option>
                    )}
                  </For>
                </select>
              </div>
              <span class="icon is-small is-left"><i class="fa-solid fa-timeline"></i></span>
            </div>
            <Show when={mapshot()}>
              <button class="button is-small" onClick={() => setShowInfo(true)}>
                <span class="icon is-small"><i class="fa-solid fa-circle-info"></i></span>
              </button>
            </Show>
          </div>
        )}
      </Show>
      <Show when={showInfo() && mapshot()}>
        <Portal mount={document.body}>
          <div class="modal is-active">
            <div class="modal-background" onClick={closeInfo} />
            <div class="modal-card" style={{ width: "90vw", "max-width": "960px" }}>
              <header class="modal-card-head">
                <p class="modal-card-title">
                  <span class="icon-text">
                    <span class="icon"><i class="fa-solid fa-circle-info"></i></span>
                    <span>Map Info</span>
                  </span>
                </p>
                <button class="delete" aria-label="close" onClick={closeInfo} />
              </header>
              <section class="modal-card-body">
                <table class="table is-fullwidth">
                  <tbody>
                    <Show when={mapshot()!.seed != null}>
                      <tr><th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-seedling"></i></span><span>Seed</span></span></th><td>{mapshot()!.seed}<CopyButton text={String(mapshot()!.seed)} /></td></tr>
                    </Show>
                    <Show when={mapshot()!.map_exchange}>
                      <tr>
                        <th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-code"></i></span><span>Map exchange</span></span></th>
                        <td>
                          <button class="button is-small" onClick={() => setShowMapExchange((v) => !v)} title={showMapExchange() ? "Hide" : "Show"}>
                            <span class="icon is-small"><i class={showMapExchange() ? "fa-solid fa-eye-slash" : "fa-solid fa-eye"} /></span>
                          </button>
                          <CopyButton text={mapshot()!.map_exchange!} />
                          <Show when={showMapExchange()}>
                            <pre style={{ "white-space": "pre-wrap", "word-break": "break-all" }}>{mapshot()!.map_exchange}</pre>
                          </Show>
                        </td>
                      </tr>
                    </Show>
                    <Show when={mapshot()!.tick != null}>
                      <tr><th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-hourglass"></i></span><span>Tick</span></span></th><td>{mapshot()!.tick!.toLocaleString()} ({formatTicks(mapshot()!.tick!)})</td></tr>
                    </Show>
                    <Show when={mapshot()!.ticks_played != null}>
                      <tr><th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-hourglass-half"></i></span><span>Ticks played</span></span></th><td>{mapshot()!.ticks_played!.toLocaleString()} ({formatTicks(mapshot()!.ticks_played!)})</td></tr>
                    </Show>
                    <Show when={mapshot()!.game_version}>
                      <tr><th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-gear"></i></span><span>Game version</span></span></th><td>{mapshot()!.game_version}</td></tr>
                    </Show>
                    <Show when={mapshot()!.active_mods}>
                      <tr>
                        <th class="map-info-label"><span class="icon-text"><span class="icon"><i class="fa-solid fa-puzzle-piece"></i></span><span>Mods</span></span></th>
                        <td>
                          <ul>
                            <For each={sortedMods(mapshot()!.active_mods!)}>
                              {([name, version]) => <li><a href={`https://mods.factorio.com/mod/${name}`} target="_blank" rel="noopener">{name}</a> {version}</li>}
                            </For>
                          </ul>
                        </td>
                      </tr>
                    </Show>
                  </tbody>
                </table>
              </section>
              <footer class="modal-card-foot">
                <button class="button" onClick={closeInfo}>
                  <span class="icon"><i class="fa-solid fa-circle-xmark"></i></span>
                  <span>Close</span>
                </button>
              </footer>
            </div>
          </div>
        </Portal>
      </Show>
      <div style={{ flex: 1, "min-height": 0 }}>
        <Suspense fallback={<div class="p-4">Loading...</div>}>
          <Show when={activeMapData()} keyed>
            {(data) => <LeafletMap mapshot={data.mapshot} assetBase={data.assetBase} />}
          </Show>
        </Suspense>
      </div>
    </div>
  );
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

const worldToLatLng = (surface: Surface, x: number, y: number): L.LatLng => {
  const ratio = surface.render_size / surface.tile_size;
  return L.latLng(-y * ratio, x * ratio);
};

const latLngToWorld = (surface: Surface, latlng: L.LatLng): { x: number; y: number } => {
  const ratio = surface.render_size / surface.tile_size;
  return { x: latlng.lng / ratio, y: -latlng.lat / ratio };
};

const surfaceLabel = (surface: Surface): string =>
  surface.surface_localised_name || surface.surface_name;

const LeafletMap = (props: { mapshot: Mapshot; assetBase: string }) => {
  let mapEl!: HTMLDivElement;

  onMount(() => {
    const { surfaces } = props.mapshot;
    if (!surfaces.length) return;

    const planetIdx = surfaces.findIndex((s) => s.is_planet);
    const defaultSurfaceIdx = planetIdx >= 0 ? planetIdx : 0;
    const initSurfaceIdx = parseInt(getParam("s") ?? "") || defaultSurfaceIdx;
    const initX = parseFloat(getParam("x") ?? "");
    const initY = parseFloat(getParam("y") ?? "");
    const initZ = parseFloat(getParam("z") ?? "");
    const showTrains = getParam("lt") === "1";
    const showTags = getParam("lg") === "1";

    const map = L.map(mapEl, {
      crs: L.CRS.Simple,
      zoomSnap: 0.1,
      zoomDelta: 1.0,
      zoomControl: false,
    });

    // Shared overlay groups — content is swapped on surface change
    const trainLayerGroup = L.layerGroup();
    const tagLayerGroup = L.layerGroup();

    // Build per-surface marker arrays and tile layers
    const baseLayers: Record<string, L.TileLayer> = {};
    const stationMarkers: Record<string, L.Marker[]> = {};
    const tagMarkers: Record<string, L.Marker[]> = {};

    for (const surface of surfaces) {
      const label = surfaceLabel(surface);
      const toLL = (x: number, y: number) => worldToLatLng(surface, x, y);
      const bounds = L.latLngBounds(
        toLL(surface.world_min.x, surface.world_min.y),
        toLL(surface.world_max.x, surface.world_max.y)
      );

      baseLayers[label] = L.tileLayer(
        `${props.assetBase}${surface.file_prefix}{z}/tile_{x}_{y}.jpg`,
        {
          tileSize: surface.render_size,
          bounds,
          noWrap: true,
          minNativeZoom: surface.zoom_min,
          maxNativeZoom: surface.zoom_max,
        }
      );

      const stationsArray = Array.isArray(surface.stations) ? surface.stations : [];
      stationMarkers[label] = stationsArray.map((s) => {
        const cx = (s.bounding_box.left_top.x + s.bounding_box.right_bottom.x) / 2;
        const cy = (s.bounding_box.left_top.y + s.bounding_box.right_bottom.y) / 2;
        return L.marker(toLL(cx, cy)).bindPopup(s.backer_name);
      });
      tagMarkers[label] = Object.values(surface.tags ?? {})
        .filter((t) => t?.position != null)
        .map((t) => L.marker(toLL(t.position.x, t.position.y)).bindPopup(t.text ?? ""));
    }

    const populateOverlays = (label: string) => {
      trainLayerGroup.clearLayers();
      tagLayerGroup.clearLayers();
      for (const m of stationMarkers[label] ?? []) trainLayerGroup.addLayer(m);
      for (const m of tagMarkers[label] ?? []) tagLayerGroup.addLayer(m);
    };

    // Activate initial surface
    const initSurface = surfaces[initSurfaceIdx] ?? surfaces[defaultSurfaceIdx];
    const initLabel = surfaceLabel(initSurface);

    baseLayers[initLabel].addTo(map);
    populateOverlays(initLabel);
    if (showTrains) trainLayerGroup.addTo(map);
    if (showTags) tagLayerGroup.addTo(map);

    L.control
      .layers(baseLayers, { "Train stations": trainLayerGroup, Tags: tagLayerGroup })
      .addTo(map);

    map.setMinZoom(initSurface.zoom_min);
    map.setMaxZoom(initSurface.zoom_max);

    if (!isNaN(initX) && !isNaN(initY) && !isNaN(initZ)) {
      const ratio = initSurface.render_size / initSurface.tile_size;
      map.setView(L.latLng(-initY * ratio, initX * ratio), initZ);
    } else {
      const bounds = L.latLngBounds(
        worldToLatLng(initSurface, initSurface.world_min.x, initSurface.world_min.y),
        worldToLatLng(initSurface, initSurface.world_max.x, initSurface.world_max.y)
      );
      map.fitBounds(bounds);
    }

    // Add after zoom bounds and initial view are set so Zoomslider computes correct track height
    new (L as unknown as { Control: { Zoomslider: new (opts: object) => L.Control } }).Control.Zoomslider({ position: "topleft", stepHeight: 20 }).addTo(map);
    L.Control.boxzoom({ position: "topleft", iconClasses: "fa-solid fa-magnifying-glass" }).addTo(map);

    let currentSurface = initSurface;

    map.on("baselayerchange", (e: L.LayersControlEvent) => {
      const idx = surfaces.findIndex((s) => surfaceLabel(s) === e.name);
      currentSurface = surfaces[idx] ?? initSurface;
      populateOverlays(e.name);
      map.setMinZoom(currentSurface.zoom_min);
      map.setMaxZoom(currentSurface.zoom_max);
      setParams({ s: (idx >= 0 ? idx : defaultSurfaceIdx).toString() });
    });

    map.on("moveend zoomend", () => {
      const world = latLngToWorld(currentSurface, map.getCenter());
      setParams({
        x: world.x.toFixed(2),
        y: world.y.toFixed(2),
        z: map.getZoom().toFixed(1),
      });
    });

    map.on("overlayadd", (e: L.LayersControlEvent) => {
      if (e.name === "Train stations") setParams({ lt: "1" });
      if (e.name === "Tags") setParams({ lg: "1" });
    });

    map.on("overlayremove", (e: L.LayersControlEvent) => {
      if (e.name === "Train stations") setParams({ lt: "0" });
      if (e.name === "Tags") setParams({ lg: "0" });
    });

    onCleanup(() => map.remove());
  });

  return <div ref={mapEl} style={{ width: "100%", height: "100%" }} />;
};
