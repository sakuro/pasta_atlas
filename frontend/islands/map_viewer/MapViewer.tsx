import { createResource, createSignal, createMemo, Show, Suspense, For, onMount, onCleanup } from "solid-js";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

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
}

interface MapData {
  generations: Generation[];
}

function getParam(key: string): string | null {
  return new URLSearchParams(window.location.search).get(key);
}

function setParams(updates: Record<string, string | null>) {
  const params = new URLSearchParams(window.location.search);
  for (const [key, value] of Object.entries(updates)) {
    if (value === null) params.delete(key);
    else params.set(key, value);
  }
  history.replaceState(null, "", `?${params}`);
}

export function MapViewer(props: { ulid: string }) {
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

  function handleGenerationChange(ulid: string) {
    setGenerationUlid(ulid);
    setParams({ generation: ulid, s: null, x: null, y: null, z: null });
  }

  return (
    <div style={{ display: "flex", "flex-direction": "column", height: "100%" }}>
      <Show when={mapData()}>
        {(data) => (
          <div style={{ padding: "0.5rem", "flex-shrink": 0 }}>
            <div class="select is-small">
              <select
                value={activeGeneration()?.ulid ?? ""}
                onChange={(e) => handleGenerationChange(e.currentTarget.value)}
              >
                <For each={data().generations}>
                  {(gen) => (
                    <option value={gen.ulid}>Tick {gen.tick.toLocaleString()}</option>
                  )}
                </For>
              </select>
            </div>
          </div>
        )}
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
}

function worldToLatLng(surface: Surface, x: number, y: number): L.LatLng {
  const ratio = surface.render_size / surface.tile_size;
  return L.latLng(-y * ratio, x * ratio);
}

function latLngToWorld(surface: Surface, latlng: L.LatLng): { x: number; y: number } {
  const ratio = surface.render_size / surface.tile_size;
  return { x: latlng.lng / ratio, y: -latlng.lat / ratio };
}

function surfaceLabel(surface: Surface): string {
  return surface.surface_localised_name || surface.surface_name;
}

function LeafletMap(props: { mapshot: Mapshot; assetBase: string }) {
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
    const showTrains = getParam("lt") !== "0";
    const showTags = getParam("lg") !== "0";

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

    function populateOverlays(label: string) {
      trainLayerGroup.clearLayers();
      tagLayerGroup.clearLayers();
      for (const m of stationMarkers[label] ?? []) trainLayerGroup.addLayer(m);
      for (const m of tagMarkers[label] ?? []) tagLayerGroup.addLayer(m);
    }

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
}
