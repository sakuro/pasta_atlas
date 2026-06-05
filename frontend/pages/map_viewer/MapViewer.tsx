import { createResource, createSignal, createMemo, Show, Suspense, onMount, onCleanup } from "solid-js";
import { useNavigate } from "@solidjs/router";
import { useToast } from "../../contexts/ToastContext";

const csrfToken = (): string =>
  document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? "";

import L from "leaflet";
import { Avatar } from "../../components/Avatar";
import { FormattedDateTime } from "../../components/FormattedDateTime";
import { MapInfoModal, type Mapshot as MapInfoMapshot } from "../../components/MapInfoModal";
import { GenerationSelect } from "./GenerationSelect";
import { MapNameEditor } from "./MapNameEditor";
import { ShareButtons } from "../../components/ShareButtons";
import { l10n } from "../../lib/l10n";
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
  `.leaflet-control-boxzoom:hover{background:var(--leaflet-ctrl-bg-hover)!important}` +
  `.pa-layer-control{position:relative}` +
  `.pa-layer-control__toggle{display:flex!important;align-items:center!important;justify-content:center!important;width:26px!important;height:26px!important;background:var(--leaflet-ctrl-bg)!important;color:var(--leaflet-ctrl-text)!important;border:2px solid rgba(0,0,0,.2);border-radius:4px;text-decoration:none!important}` +
  `.pa-layer-control__toggle:hover{background:var(--leaflet-ctrl-bg-hover)!important}` +
  `.pa-layer-control__panel{position:absolute;right:0;top:calc(100% + 4px);background:var(--leaflet-ctrl-bg);color:var(--leaflet-ctrl-text);border:2px solid rgba(0,0,0,.2);border-radius:4px;min-width:160px;padding:.25rem 0;box-shadow:0 1px 5px rgba(0,0,0,.4);z-index:1000}` +
  `.pa-layer-control__heading{padding:.2rem .5rem;font-size:.7rem;font-weight:bold;opacity:.7}` +
  `.pa-layer-control__item{display:flex;align-items:center;gap:.4rem;padding:.2rem .5rem;font-size:.75rem;cursor:pointer;white-space:nowrap}` +
  `.pa-layer-control__item:hover{background:var(--leaflet-ctrl-bg-hover)}` +
  `.pa-layer-control__divider{margin:.25rem 0;border:none;border-top:1px solid var(--leaflet-ctrl-border)}`;
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
  surface_localised_name: string | string[];
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

export const MapViewer = (props: MapViewerProps) => {
  const navigate = useNavigate();
  const { showToast } = useToast();

  const [mapData] = createResource(() =>
    fetch(`/api/v1/maps/${props.ulid}`).then((r) => r.json() as Promise<MapData>)
  );

  const [generationUlid, setGenerationUlid] = createSignal<string | null>(getParam("generation"));

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
  const [showDeleteConfirm, setShowDeleteConfirm] = createSignal(false);

  const handleDelete = async () => {
    const res = await fetch(`/api/v1/maps/${props.ulid}/deletion_requests`, {
      method: "POST",
      headers: { "X-CSRF-Token": csrfToken() },
      redirect: "manual",
    });
    if (res.type === "opaqueredirect") {
      showToast("map-deletion-requested", "info");
      navigate("/");
    }
  };

  const isOwner = () => props.viewerName !== null && props.viewerName === props.authorName;

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
        <MapNameEditor
          ulid={props.ulid}
          initialName={props.displayName}
          isOwner={isOwner()}
          onSave={(prev, next) => { document.title = document.title.replace(prev, next); }}
        />
        <Show
          when={props.authorName !== "guest"}
          fallback={
            <span class="is-flex is-align-items-center" style={{ "flex-shrink": 0, gap: "0.4rem" }}>
              <Avatar url={props.authorAvatarUrl} size={24} />
              <span class="is-size-7">{props.authorDisplayName}</span>
            </span>
          }
        >
          <a href={`/@${props.authorName}`} class="is-flex is-align-items-center" style={{ "flex-shrink": 0, gap: "0.4rem" }}>
            <Avatar url={props.authorAvatarUrl} size={24} />
            <span class="is-size-7">{props.authorDisplayName}</span>
          </a>
        </Show>
        <Show when={props.updatedAt}>
          {(iso) => (
            <span class="is-size-7 has-text-grey" style={{ "flex-shrink": 0 }}>
              <FormattedDateTime dateTime={iso()} />
            </span>
          )}
        </Show>
        <div style={{ flex: 1 }} />
        <Show when={mapData()}>
          {(data) => (
            <GenerationSelect
              generations={data().generations}
              value={activeGeneration()?.ulid ?? ""}
              onChange={handleGenerationChange}
            />
          )}
        </Show>
        <Show when={mapshot()}>
          <div class="buttons has-addons mb-0">
            <button class="button is-small" onClick={() => setShowInfo(true)} data-l10n-id="map-info-button">
              <span class="icon is-small"><i class="fa-solid fa-circle-info" /></span>
            </button>
            <Show when={isOwner()}>
              <button class="button is-small" onClick={() => setShowDeleteConfirm(true)} data-l10n-id="map-delete-button">
                <span class="icon is-small has-text-danger"><i class="fa-solid fa-trash" /></span>
              </button>
            </Show>
          </div>
        </Show>
        <Show when={activeGeneration()}>
          {(gen) => (
            <ShareButtons
              mapPath={`/maps/${props.ulid}?generation=${gen().ulid}`}
              mapName={mapData()!.display_name}
            />
          )}
        </Show>
      </div>
      <Show when={showInfo() && mapshot()}>
        <MapInfoModal mapshot={mapshot()!} onClose={() => setShowInfo(false)} />
      </Show>
      <Show when={showDeleteConfirm()}>
        <div class="modal is-active">
          <div class="modal-background" onClick={() => setShowDeleteConfirm(false)} />
          <div class="modal-card">
            <header class="modal-card-head">
              <p class="modal-card-title"><span data-l10n-id="map-delete-confirm-title" /></p>
              <button class="delete" aria-label="close" onClick={() => setShowDeleteConfirm(false)} />
            </header>
            <section class="modal-card-body">
              <span data-l10n-id="map-delete-confirm-message" />
            </section>
            <footer class="modal-card-foot" style={{ gap: "0.5rem" }}>
              <button class="button is-danger" onClick={() => void handleDelete()}>
                <span data-l10n-id="map-delete-confirm-button" />
              </button>
              <button class="button" onClick={() => setShowDeleteConfirm(false)}>
                <span data-l10n-id="map-delete-cancel-button" />
              </button>
            </footer>
          </div>
        </div>
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

interface LayerControlGroup {
  heading: string;
  entries: Array<{ label: string; layer: L.TileLayer }>;
}

interface LayerControlOverlay {
  label: string;
  group: L.LayerGroup;
  visible: boolean;
}

class LayerControl extends L.Control {
  private _activeLayer: L.TileLayer;
  private _groups: LayerControlGroup[];
  private _overlays: LayerControlOverlay[];
  private _initLabel: string;

  constructor(
    groups: LayerControlGroup[],
    overlays: LayerControlOverlay[],
    initLabel: string,
    initLayer: L.TileLayer
  ) {
    super({ position: "topright" });
    this._groups = groups;
    this._overlays = overlays;
    this._initLabel = initLabel;
    this._activeLayer = initLayer;
  }

  onAdd(map: L.Map): HTMLElement {
    const container = L.DomUtil.create("div", "leaflet-control pa-layer-control");
    L.DomEvent.disableClickPropagation(container);
    L.DomEvent.disableScrollPropagation(container);

    const btn = L.DomUtil.create("a", "pa-layer-control__toggle", container);
    btn.href = "#";
    btn.setAttribute("role", "button");
    btn.setAttribute("aria-label", "Layers");
    btn.innerHTML = `<i class="fa-solid fa-layer-group"></i>`;

    const panel = L.DomUtil.create("div", "pa-layer-control__panel", container);
    panel.style.display = "none";

    const visibleGroups = this._groups.filter((g) => g.entries.length > 0);
    const showHeadings = visibleGroups.length > 1;

    for (const group of visibleGroups) {
      if (showHeadings) {
        const h = L.DomUtil.create("p", "pa-layer-control__heading", panel);
        h.textContent = group.heading;
      }
      for (const entry of group.entries) {
        const lbl = L.DomUtil.create("label", "pa-layer-control__item", panel);
        const radio = document.createElement("input");
        radio.type = "radio";
        radio.name = "pa-base-layer";
        radio.checked = entry.label === this._initLabel;
        const span = document.createElement("span");
        span.innerHTML = entry.label;
        lbl.appendChild(radio);
        lbl.appendChild(span);
        L.DomEvent.on(radio, "change", () => {
          map.removeLayer(this._activeLayer);
          this._activeLayer = entry.layer;
          this._activeLayer.addTo(map);
          map.fire("baselayerchange", { layer: entry.layer, name: entry.label });
        });
      }
    }

    L.DomUtil.create("hr", "pa-layer-control__divider", panel);

    for (const overlay of this._overlays) {
      const lbl = L.DomUtil.create("label", "pa-layer-control__item", panel);
      const checkbox = document.createElement("input");
      checkbox.type = "checkbox";
      checkbox.checked = overlay.visible;
      const span = document.createElement("span");
      span.textContent = overlay.label;
      lbl.appendChild(checkbox);
      lbl.appendChild(span);
      L.DomEvent.on(checkbox, "change", () => {
        if (checkbox.checked) {
          overlay.group.addTo(map);
          map.fire("overlayadd", { layer: overlay.group, name: overlay.label });
        } else {
          map.removeLayer(overlay.group);
          map.fire("overlayremove", { layer: overlay.group, name: overlay.label });
        }
      });
    }

    L.DomEvent.on(btn, "click", (e) => {
      L.DomEvent.preventDefault(e);
      panel.style.display = panel.style.display === "none" ? "block" : "none";
    });

    return container;
  }

  onRemove(_map: L.Map): void {}
}

const LeafletMap = (props: { mapshot: Mapshot; assetBase: string }) => {
  let mapEl!: HTMLDivElement;

  onMount(async () => {
    const { surfaces } = props.mapshot;
    if (!surfaces.length) return;

    const planetSurfaces = surfaces.filter((s) => s.is_planet);
    const [trainStationsLabel, tagsLabel, planetsHeading, spacePlatformsHeading, otherHeading, ...ftlPlanetNames] = await l10n.formatValues([
      { id: "map-layer-train-stations" },
      { id: "map-layer-tags" },
      { id: "map-layer-group-planets" },
      { id: "map-layer-group-space-platforms" },
      { id: "map-layer-group-other" },
      ...planetSurfaces.map((s) => ({ id: `surface-${s.surface_name}` })),
    ]);
    const ftlNameBySurfaceName: Record<string, string> = {};
    planetSurfaces.forEach((s, i) => { ftlNameBySurfaceName[s.surface_name] = ftlPlanetNames[i]; });

    type SubsurfaceName = [string, [string], string];
    const isSubsurfaceName = (v: unknown): v is SubsurfaceName =>
      Array.isArray(v) && v[0] === "subsurface.subsurface-name" &&
      Array.isArray(v[1]) && typeof v[2] === "string";

    const subsurfaceEntries = surfaces.map((s, i) => {
      if (!isSubsurfaceName(s.surface_localised_name)) return null;
      const planetKey = s.surface_localised_name[1][0];
      const planetName = planetKey.slice(planetKey.lastIndexOf(".") + 1);
      const planet = ftlNameBySurfaceName[planetName] ?? planetName;
      return { idx: i, planet, level: s.surface_localised_name[2] };
    });
    const subsurfaceToResolve = subsurfaceEntries.filter((e): e is NonNullable<typeof e> => e !== null);
    const subsurfaceFormatted = new Map<number, string>();
    if (subsurfaceToResolve.length > 0) {
      const results = await l10n.formatValues(
        subsurfaceToResolve.map(({ planet, level }) => ({ id: "subsurface-name", args: { planet, level } }))
      );
      subsurfaceToResolve.forEach(({ idx }, i) => {
        if (results[i] !== null) subsurfaceFormatted.set(idx, results[i]!);
      });
    }

    const labels = surfaces.map((s, i) => {
      const subsurface = subsurfaceFormatted.get(i);
      if (subsurface !== undefined) return renderRichText(subsurface);
      const rawName = ftlNameBySurfaceName[s.surface_name] ?? s.surface_localised_name ?? s.surface_name;
      const name = Array.isArray(rawName) ? String(rawName) : rawName;
      const prefix = s.is_planet ? `[planet=${s.surface_name}] ` : "";
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
        .map((t) => L.marker(toLL(t.position.x, t.position.y)).bindPopup(renderRichText(t.text ?? "")));
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

    const groupedEntries: Record<"planets" | "spacePlatforms" | "other", Array<{ label: string; layer: L.TileLayer }>> = {
      planets: [],
      spacePlatforms: [],
      other: [],
    };
    for (const i of sortedIndices) {
      const s = surfaces[i];
      const entry = { label: labels[i], layer: baseLayers[labels[i]] };
      if (s.is_planet) groupedEntries.planets.push(entry);
      else if (s.is_space_platform) groupedEntries.spacePlatforms.push(entry);
      else groupedEntries.other.push(entry);
    }

    new LayerControl(
      [
        { heading: planetsHeading, entries: groupedEntries.planets },
        { heading: spacePlatformsHeading, entries: groupedEntries.spacePlatforms },
        { heading: otherHeading, entries: groupedEntries.other },
      ],
      [
        { label: trainStationsLabel, group: trainLayerGroup, visible: showTrains },
        { label: tagsLabel, group: tagLayerGroup, visible: showTags },
      ],
      initLabel,
      baseLayers[initLabel]
    ).addTo(map);

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
