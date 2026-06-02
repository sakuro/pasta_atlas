import { createSignal, Show } from "solid-js";
import { useToast } from "../../contexts/ToastContext";

const segmenter = new Intl.Segmenter();
const MAX_GRAPHEMES = 30;

const csrfToken = (): string =>
  document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? "";

interface MapNameEditorProps {
  ulid: string;
  initialName: string;
  isOwner: boolean;
  onSave: (prev: string, next: string) => void;
}

export const MapNameEditor = (props: MapNameEditorProps) => {
  const { showToast } = useToast();
  const [displayName, setDisplayName] = createSignal(props.initialName);
  const [isEditing, setIsEditing] = createSignal(false);
  const [editValue, setEditValue] = createSignal("");
  const editGraphemeCount = () => [...segmenter.segment(editValue())].length;

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
      setIsEditing(false);
      props.onSave(prev, data.display_name);
    } else if (res.status === 422) {
      const data = await res.json() as { error: string };
      showToast(data.error, "danger");
    }
  };

  return (
    <Show
      when={isEditing()}
      fallback={
        <span style={{ display: "flex", "align-items": "center", gap: "0.25rem", "min-width": 0, "flex-shrink": 1, "margin-right": "0.25rem" }}>
          <span class="is-size-7 has-text-weight-semibold" style={{ overflow: "hidden", "text-overflow": "ellipsis", "white-space": "nowrap", "min-width": 0 }}>
            {displayName()}
          </span>
          <Show when={props.isOwner}>
            <button class="button is-small" onClick={startEdit} data-l10n-id="map-name-edit-button">
              <span class="icon is-small"><i class="fa-solid fa-pencil" /></span>
            </button>
          </Show>
        </span>
      }
    >
      <div class="field has-addons mb-0" style={{ "flex-shrink": 1, "min-width": 0, "margin-right": "0.25rem" }}>
        <div class="control">
          <input
            class="input is-small"
            type="text"
            value={editValue()}
            onInput={(e) => setEditValue(e.currentTarget.value)}
            onKeyDown={(e) => { if (e.key === "Enter") void saveEdit(); if (e.key === "Escape") cancelEdit(); }}
            ref={(el) => { el.focus(); el.select(); }}
            style={{ "min-width": "8rem", "max-width": "20rem" }}
          />
        </div>
        <div class="control">
          <span class={`button is-small is-static ${editGraphemeCount() > MAX_GRAPHEMES ? "has-text-danger" : "has-text-grey-light"}`}>
            {editGraphemeCount()} / {MAX_GRAPHEMES}
          </span>
        </div>
        <div class="control">
          <button class="button is-small is-success" onClick={() => void saveEdit()} data-l10n-id="map-name-save-button">
            <span class="icon is-small"><i class="fa-solid fa-check" /></span>
          </button>
        </div>
        <div class="control">
          <button class="button is-small" onClick={cancelEdit} data-l10n-id="map-name-cancel-button">
            <span class="icon is-small"><i class="fa-solid fa-xmark" /></span>
          </button>
        </div>
      </div>
    </Show>
  );
};
