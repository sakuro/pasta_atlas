import { onMount, onCleanup } from "solid-js";
import L from "leaflet";
import { type Mapshot as MapInfoMapshot } from "../../../components/MapInfoModal";
import { l10n } from "../../../lib/l10n";
import { renderRichText } from "../richtext";
import { getParam, setParams } from "../url_params";
import { LayerControl } from "./LayerControl";
import { StationMarker, TagMarker } from "./markers";
import { BoxZoomControl } from "./box_zoom";
import { ZoomSliderControl } from "./zoom_slider";
import "leaflet/dist/leaflet.css";
import markerIcon from "leaflet/dist/images/marker-icon.png";
import markerIcon2x from "leaflet/dist/images/marker-icon-2x.png";
import markerShadow from "leaflet/dist/images/marker-shadow.png";

// Vite breaks Leaflet's runtime URL resolution for default marker images
delete (L.Icon.Default.prototype as unknown as Record<string, unknown>)["_getIconUrl"];
L.Icon.Default.mergeOptions({ iconUrl: markerIcon, iconRetinaUrl: markerIcon2x, shadowUrl: markerShadow });

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

export interface Mapshot extends MapInfoMapshot {
  surfaces: Surface[];
}

const worldToLatLng = (surface: Surface, x: number, y: number): L.LatLng => {
  const ratio = surface.render_size / surface.tile_size;
  return L.latLng(-y * ratio, x * ratio);
};

const latLngToWorld = (surface: Surface, latlng: L.LatLng): { x: number; y: number } => {
  const ratio = surface.render_size / surface.tile_size;
  return { x: latlng.lng / ratio, y: -latlng.lat / ratio };
};

export const LeafletMap = (props: { mapshot: Mapshot; assetBase: string }) => {
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
        return new StationMarker(toLL(cx, cy), s.backer_name);
      });
      tagMarkers[label] = Object.values(surface.tags ?? {})
        .filter((t) => t?.position != null)
        .map((t) => new TagMarker(toLL(t.position.x, t.position.y), t.text ?? ""));
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

    // Add after zoom bounds and initial view are set so track height is computed correctly
    new ZoomSliderControl(20).addTo(map);
    new BoxZoomControl().addTo(map);

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
