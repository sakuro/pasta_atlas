import L from "leaflet";
import "../theme.css";
import "./BoxZoom.css";

export class BoxZoomControl extends L.Control {
  constructor() {
    super({ position: "topleft" });
  }

  onAdd(map: L.Map): HTMLElement {
    const container = L.DomUtil.create("div", "leaflet-bar leaflet-control");
    L.DomEvent.disableClickPropagation(container);
    L.DomEvent.disableScrollPropagation(container);

    const btn = L.DomUtil.create("a", "pa-boxzoom-btn", container);
    btn.href = "#";
    btn.setAttribute("role", "button");
    btn.title = "Box zoom";
    btn.innerHTML = `<i class="fa-solid fa-magnifying-glass"></i>`;

    L.DomEvent.on(btn, "click", (e) => {
      L.DomEvent.preventDefault(e);
      this._activate(map);
    });

    return container;
  }

  onRemove(_map: L.Map): void {}

  private _activate(map: L.Map): void {
    const overlay = L.DomUtil.create("div", "pa-boxzoom-overlay", map.getContainer());
    const rect = L.DomUtil.create("div", "pa-boxzoom-rect", overlay);

    let startPoint: L.Point | null = null;

    const onMouseMove = (e: MouseEvent) => {
      if (!startPoint) return;
      const cur = map.mouseEventToContainerPoint(e);
      rect.style.left   = `${Math.min(startPoint.x, cur.x)}px`;
      rect.style.top    = `${Math.min(startPoint.y, cur.y)}px`;
      rect.style.width  = `${Math.abs(cur.x - startPoint.x)}px`;
      rect.style.height = `${Math.abs(cur.y - startPoint.y)}px`;
      rect.style.display = "block";
    };

    const cleanup = () => {
      document.removeEventListener("mousemove", onMouseMove);
      document.removeEventListener("mouseup", onMouseUp);
      document.removeEventListener("keydown", onKeyDown);
      map.dragging.enable();
      overlay.remove();
    };

    const onMouseUp = (e: MouseEvent) => {
      if (startPoint) {
        const end = map.mouseEventToContainerPoint(e);
        if (Math.abs(end.x - startPoint.x) > 10 && Math.abs(end.y - startPoint.y) > 10) {
          const sw = map.containerPointToLatLng(L.point(Math.min(startPoint.x, end.x), Math.max(startPoint.y, end.y)));
          const ne = map.containerPointToLatLng(L.point(Math.max(startPoint.x, end.x), Math.min(startPoint.y, end.y)));
          map.fitBounds(L.latLngBounds(sw, ne));
        }
      }
      cleanup();
    };

    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") cleanup();
    };

    L.DomEvent.on(overlay, "mousedown", (e) => {
      L.DomEvent.preventDefault(e);
      startPoint = map.mouseEventToContainerPoint(e as MouseEvent);
      map.dragging.disable();
      document.addEventListener("mousemove", onMouseMove);
      document.addEventListener("mouseup", onMouseUp);
      document.addEventListener("keydown", onKeyDown);
    });
  }
}
