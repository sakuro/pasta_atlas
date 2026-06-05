import L from "leaflet";
import "./LayerControl.css";

export interface LayerControlGroup {
  heading: string;
  entries: Array<{ label: string; layer: L.TileLayer }>;
}

export interface LayerControlOverlay {
  label: string;
  group: L.LayerGroup;
  visible: boolean;
}

export class LayerControl extends L.Control {
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
    const container = L.DomUtil.create("div", "leaflet-bar leaflet-control pa-layer-control");
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
