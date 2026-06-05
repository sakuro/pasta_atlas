import { createResource, createSignal, createMemo, Show, Suspense, onMount } from "solid-js";
import { useNavigate } from "@solidjs/router";
import { useToast } from "../../contexts/ToastContext";

const csrfToken = (): string =>
  document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? "";

import { Avatar } from "../../components/Avatar";
import { FormattedDateTime } from "../../components/FormattedDateTime";
import { MapInfoModal } from "../../components/MapInfoModal";
import { GenerationSelect } from "./GenerationSelect";
import { MapNameEditor } from "./MapNameEditor";
import { ShareButtons } from "../../components/ShareButtons";
import { LeafletMap, type Mapshot } from "./leaflet/LeafletMap";
import { getParam, setParams } from "./url_params";

interface Generation {
  ulid: string;
  tick: number;
  metadata_url: string;
}

interface MapData {
  ulid: string;
  display_name: string;
  owner: { name: string };
  generations: Generation[];
}

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
