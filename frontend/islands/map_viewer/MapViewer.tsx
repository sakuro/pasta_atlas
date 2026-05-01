import { createResource, Show, Suspense, onMount, onCleanup } from "solid-js";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

interface Generation {
  ulid: string;
  tick: number;
  metadata_url: string;
}

interface Surface {
  surface_idx: number;
  surface_localised_name: string;
  surface_name: string;
  file_prefix: string;
  tile_size: number;
  render_size: number;
  world_min: { x: number; y: number };
  world_max: { x: number; y: number };
  zoom_min: number;
  zoom_max: number;
}

interface Mapshot {
  surfaces: Surface[];
}

interface MapData {
  generations: Generation[];
}

export function MapViewer(props: { ulid: string }) {
  const [mapData] = createResource(() =>
    fetch(`/api/v1/maps/${props.ulid}`).then((r) => r.json() as Promise<MapData>)
  );

  const latestGeneration = () =>
    mapData()?.generations.reduce((a, b) => (a.tick > b.tick ? a : b));

  const [mapshot] = createResource(
    () => latestGeneration()?.metadata_url,
    (url) => fetch(url).then((r) => r.json() as Promise<Mapshot>)
  );

  const assetBase = () =>
    latestGeneration()?.metadata_url.replace(/mapshot\.json$/, "") ?? "";

  return (
    <Suspense fallback={<div>Loading...</div>}>
      <Show when={mapshot()} keyed>
        {(data) => <LeafletMap mapshot={data} assetBase={assetBase()} />}
      </Show>
    </Suspense>
  );
}

function LeafletMap(props: { mapshot: Mapshot; assetBase: string }) {
  let mapEl!: HTMLDivElement;

  onMount(() => {
    const surface = props.mapshot.surfaces[0];
    if (!surface) return;

    const map = L.map(mapEl, {
      crs: L.CRS.Simple,
      zoomSnap: 0.1,
      zoomDelta: 1.0,
    });

    const worldToLatLng = (x: number, y: number) => {
      const ratio = surface.render_size / surface.tile_size;
      return L.latLng(-y * ratio, x * ratio);
    };

    const bounds = L.latLngBounds(
      worldToLatLng(surface.world_min.x, surface.world_min.y),
      worldToLatLng(surface.world_max.x, surface.world_max.y)
    );

    L.tileLayer(`${props.assetBase}${surface.file_prefix}{z}/tile_{x}_{y}.jpg`, {
      tileSize: surface.render_size,
      bounds,
      noWrap: true,
      minNativeZoom: surface.zoom_min,
      maxNativeZoom: surface.zoom_max,
    }).addTo(map);

    map.setMinZoom(surface.zoom_min);
    map.setMaxZoom(surface.zoom_max);
    map.fitBounds(bounds);

    onCleanup(() => map.remove());
  });

  return <div ref={mapEl} style={{ width: "100%", height: "100%" }} />;
}
