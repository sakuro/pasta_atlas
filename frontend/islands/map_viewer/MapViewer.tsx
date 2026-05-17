import { createResource, createSignal, createMemo, Show, Suspense, For, onMount, onCleanup } from "solid-js";

const csrfToken = (): string =>
  document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? "";
import L from "leaflet";
import { MapInfoModal, formatTicks, type Mapshot as MapInfoMapshot } from "../../components/MapInfoModal";
import { ShareButtons } from "../share_buttons/ShareButtons";
import { l10n } from "../../l10n";
import { renderRichText } from "./richtext";
import "leaflet/dist/leaflet.css";
import "./richtext.css";
import "leaflet.zoomslider";
import "leaflet-control-boxzoom";
import zoomsliderCss from "leaflet.zoomslider/src/L.Control.Zoomslider.css?raw";
import boxzoomCss from "leaflet-control-boxzoom/dist/leaflet-control-boxzoom.css?raw";

const pluginStyle = document.createElement("style");
pluginStyle.textContent = zoomsliderCss + boxzoomCss +
  `.leaflet-control-zoomslider-body,.leaflet-control-zoomslider-knob{box-sizing:content-box!important}` +
  `.leaflet-control-boxzoom{display:flex!important;align-items:center!important;justify-content:center!important;width:26px!important;height:26px!important;box-sizing:content-box!important}` +
  `.leaflet-touch .leaflet-control-boxzoom{width:30px!important;height:30px!important}` +
  `.leaflet-control-boxzoom i{font-size:18px;color:var(--leaflet-ctrl-text)!important}` +
  `.leaflet-bar a{background:var(--leaflet-ctrl-bg)!important;border-bottom-color:var(--leaflet-ctrl-border)!important;color:var(--leaflet-ctrl-text)!important}` +
  `.leaflet-bar a:hover{background:var(--leaflet-ctrl-bg-hover)!important}` +
  `.leaflet-control-layers{background:var(--leaflet-ctrl-bg)!important;color:var(--leaflet-ctrl-text)!important}` +
  `.leaflet-control-zoomslider-wrap{background:var(--leaflet-ctrl-bg)!important}` +
  `.leaflet-control-zoomslider-body{background:var(--leaflet-ctrl-slider-track)!important}` +
  `.leaflet-control-zoomslider-knob{background:var(--leaflet-ctrl-slider-knob)!important;border-color:var(--leaflet-ctrl-slider-knob-border)!important}` +
  `.leaflet-control-boxzoom{background:var(--leaflet-ctrl-bg)!important;color:var(--leaflet-ctrl-text)!important}` +
  `.leaflet-control-boxzoom:hover{background:var(--leaflet-ctrl-bg-hover)!important}`;
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
  is_space_platform: boolean;
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

interface Mapshot extends MapInfoMapshot {
  surfaces: Surface[];
}

interface MapData {
  ulid: string;
  display_name: string;
  owner: { name: string };
  generations: Generation[];
}

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

interface MapViewerProps {
  ulid: string;
  displayName: string;
  authorName: string;
  authorDisplayName: string;
  authorAvatarUrl: string | null;
  updatedAt: string | null;
  viewerName: string | null;
}

const formatDate = (iso: string): string => {
  const locale = document.documentElement.lang || "en";
  return new Intl.DateTimeFormat(locale, { dateStyle: "medium" }).format(new Date(iso));
};

export const MapViewer = (props: MapViewerProps) => {
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

  const [displayName, setDisplayName] = createSignal(props.displayName);
  const [isEditing, setIsEditing] = createSignal(false);
  const [editValue, setEditValue] = createSignal("");
  const isOwner = () => props.viewerName !== null && props.viewerName === props.authorName;

  const startEdit = () => {
    setEditValue(displayName());
    setIsEditing(true);
  };

  const cancelEdit = () => setIsEditing(false);

  const saveEdit = async () => {
    const name = editValue().trim();
    const res = await fetch(`/api/v1/maps/${props.ulid}/name`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
      body: JSON.stringify({ name }),
    });
    if (res.ok) {
      const data = await res.json() as { display_name: string };
      const prev = displayName();
      setDisplayName(data.display_name);
      document.title = document.title.replace(prev, data.display_name);
      setIsEditing(false);
    }
  };

  onMount(() => {
    document.title = `${props.displayName} - ${document.title}`;
  });

  const handleGenerationChange = (ulid: string) => {
    setGenerationUlid(ulid);
    setParams({ generation: ulid, s: null, x: null, y: null, z: null });
  };

  return (
    <div style={{ display: "flex", "flex-direction": "column", height: "100%" }}>
      <div style={{ padding: "0.25rem 0.5rem", "flex-shrink": 0, display: "flex", gap: "0.5rem", "align-items": "center" }}>
        <Show
          when={isEditing()}
          fallback={
            <span style={{ display: "flex", "align-items": "center", gap: "0.25rem", "min-width": 0, "flex-shrink": 1, "margin-right": "0.25rem" }}>
              <span class="is-size-7 has-text-weight-semibold" style={{ overflow: "hidden", "text-overflow": "ellipsis", "white-space": "nowrap", "min-width": 0 }}>
                {displayName()}
              </span>
              <Show when={isOwner()}>
                <button
                  class="button is-ghost is-small"
                  style={{ padding: 0, height: "auto", "min-width": 0, "flex-shrink": 0 }}
                  onClick={startEdit}
                  data-l10n-id="map-name-edit-button"
                >
                  <span class="icon is-small"><i class="fa-solid fa-pencil" /></span>
                </button>
              </Show>
            </span>
          }
        >
          <span style={{ display: "flex", "align-items": "center", gap: "0.25rem", "flex-shrink": 1, "min-width": 0, "margin-right": "0.25rem" }}>
            <input
              class="input is-small"
              type="text"
              maxLength={255}
              value={editValue()}
              onInput={(e) => setEditValue(e.currentTarget.value)}
              onKeyDown={(e) => { if (e.key === "Enter") void saveEdit(); if (e.key === "Escape") cancelEdit(); }}
              ref={(el) => { el.focus(); el.select(); }}
              style={{ "min-width": "8rem", "max-width": "20rem" }}
            />
            <button class="button is-small is-success" onClick={() => void saveEdit()} data-l10n-id="map-name-save-button">
              <span class="icon is-small"><i class="fa-solid fa-check" /></span>
            </button>
            <button class="button is-small" onClick={cancelEdit} data-l10n-id="map-name-cancel-button">
              <span class="icon is-small"><i class="fa-solid fa-xmark" /></span>
            </button>
          </span>
        </Show>
        <a href={`/@${props.authorName}`} class="is-flex is-align-items-center" style={{ "flex-shrink": 0, gap: "0.4rem" }}>
          <Show when={props.authorAvatarUrl} fallback={<i class="fa-solid fa-circle-user" style={{ "font-size": "24px" }} />}>
            {(url) => <img src={url()} width="24" height="24" style={{ "border-radius": "50%" }} />}
          </Show>
          <span class="is-size-7">{props.authorDisplayName}</span>
        </a>
        <Show when={props.updatedAt}>
          {(iso) => (
            <span class="is-size-7 has-text-grey" style={{ "flex-shrink": 0 }}>
              <span class="icon-text">
                <span class="icon is-small"><i class="fa-regular fa-calendar" /></span>
                <time datetime={iso()}>{formatDate(iso())}</time>
              </span>
            </span>
          )}
        </Show>
        <div style={{ flex: 1 }} />
        <Show when={mapData()}>
          {(data) => (
            <div class="control has-icons-left" style={{ "flex-shrink": 0 }}>
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
              <span class="icon is-small is-left"><i class="fa-solid fa-timeline" /></span>
            </div>
          )}
        </Show>
        <Show when={mapshot()}>
          <button class="button is-small" onClick={() => setShowInfo(true)} data-l10n-id="map-info-button">
            <span class="icon is-small"><i class="fa-solid fa-circle-info" /></span>
          </button>
        </Show>
        <Show when={mapData()}>
          {(data) => (
            <ShareButtons
              mapPath={`/@${data().owner.name}/maps/${data().ulid}`}
              mapName={data().display_name}
            />
          )}
        </Show>
      </div>
      <Show when={showInfo() && mapshot()}>
        <MapInfoModal mapshot={mapshot()!} onClose={() => setShowInfo(false)} />
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

const worldToLatLng = (surface: Surface, x: number, y: number): L.LatLng => {
  const ratio = surface.render_size / surface.tile_size;
  return L.latLng(-y * ratio, x * ratio);
};

const latLngToWorld = (surface: Surface, latlng: L.LatLng): { x: number; y: number } => {
  const ratio = surface.render_size / surface.tile_size;
  return { x: latlng.lng / ratio, y: -latlng.lat / ratio };
};

const LeafletMap = (props: { mapshot: Mapshot; assetBase: string }) => {
  let mapEl!: HTMLDivElement;

  onMount(async () => {
    const { surfaces } = props.mapshot;
    if (!surfaces.length) return;

    const planetSurfaces = surfaces.filter((s) => s.is_planet);
    const [trainStationsLabel, tagsLabel, ...ftlPlanetNames] = await l10n.formatValues([
      { id: "map-layer-train-stations" },
      { id: "map-layer-tags" },
      ...planetSurfaces.map((s) => ({ id: `surface-${s.surface_name}` })),
    ]);
    const ftlNameBySurfaceName: Record<string, string> = {};
    planetSurfaces.forEach((s, i) => { ftlNameBySurfaceName[s.surface_name] = ftlPlanetNames[i]; });
    const labels = surfaces.map((s) => {
      const name = ftlNameBySurfaceName[s.surface_name] ?? (s.surface_localised_name || s.surface_name);
      const prefix = s.is_planet
        ? `[planet=${s.surface_name}] `
        : s.is_space_platform
        ? "[img=surface/space-platform] "
        : "";
      return renderRichText(prefix + name);
    });

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

    // Sort indices: planets → space platforms → others
    const cmp = (a: number, b: number): -1 | 0 | 1 => a < b ? -1 : a > b ? 1 : 0;
    const groupOrder = (s: Surface): number => s.is_planet ? 0 : s.is_space_platform ? 1 : 2;
    const sortedIndices = surfaces.map((_, i) => i).sort((a, b) =>
      cmp(groupOrder(surfaces[a]), groupOrder(surfaces[b])) || cmp(surfaces[a].surface_idx, surfaces[b].surface_idx)
    );

    // Build per-surface marker arrays and tile layers (in sorted display order)
    const baseLayers: Record<string, L.TileLayer> = {};
    const stationMarkers: Record<string, L.Marker[]> = {};
    const tagMarkers: Record<string, L.Marker[]> = {};

    for (const i of sortedIndices) {
      const surface = surfaces[i];
      const label = labels[i];
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
        return L.marker(toLL(cx, cy)).bindPopup(renderRichText(s.backer_name));
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
    const resolvedInitIdx = surfaces[initSurfaceIdx] !== undefined ? initSurfaceIdx : defaultSurfaceIdx;
    const initSurface = surfaces[resolvedInitIdx];
    const initLabel = labels[resolvedInitIdx];

    baseLayers[initLabel].addTo(map);
    populateOverlays(initLabel);
    if (showTrains) trainLayerGroup.addTo(map);
    if (showTags) tagLayerGroup.addTo(map);

    L.control
      .layers(baseLayers, { [trainStationsLabel]: trainLayerGroup, [tagsLabel]: tagLayerGroup })
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
      const idx = labels.findIndex((l) => l === e.name);
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
      if (e.name === trainStationsLabel) setParams({ lt: "1" });
      if (e.name === tagsLabel) setParams({ lg: "1" });
    });

    map.on("overlayremove", (e: L.LayersControlEvent) => {
      if (e.name === trainStationsLabel) setParams({ lt: "0" });
      if (e.name === tagsLabel) setParams({ lg: "0" });
    });

    onCleanup(() => map.remove());
  });

  return <div ref={mapEl} style={{ width: "100%", height: "100%" }} />;
};
