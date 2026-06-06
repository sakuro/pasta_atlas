import L from "leaflet";
import "../theme.css";
import "./ZoomSlider.css";

const KNOB_HEIGHT = 8;

export class ZoomSliderControl extends L.Control {
  private readonly _stepHeight: number;
  private readonly _zoomInTitle: string;
  private readonly _zoomOutTitle: string;
  private _map: L.Map | null = null;
  private _track: HTMLElement | null = null;
  private _knob: HTMLElement | null = null;
  private _btnIn: HTMLElement | null = null;
  private _btnOut: HTMLElement | null = null;

  constructor(stepHeight = 20, zoomInTitle = "Zoom in", zoomOutTitle = "Zoom out") {
    super({ position: "topleft" });
    this._stepHeight = stepHeight;
    this._zoomInTitle = zoomInTitle;
    this._zoomOutTitle = zoomOutTitle;
  }

  onAdd(map: L.Map): HTMLElement {
    this._map = map;

    const container = L.DomUtil.create("div", "leaflet-bar leaflet-control pa-zoomslider");
    L.DomEvent.disableClickPropagation(container);
    L.DomEvent.disableScrollPropagation(container);

    this._btnIn = L.DomUtil.create("a", "pa-zoomslider-in", container);
    this._btnIn.setAttribute("href", "#");
    this._btnIn.setAttribute("role", "button");
    this._btnIn.setAttribute("aria-label", this._zoomInTitle);
    this._btnIn.dataset.tooltip = this._zoomInTitle;
    this._btnIn.textContent = "+";

    this._track = L.DomUtil.create("div", "pa-zoomslider-track", container);
    this._knob = L.DomUtil.create("div", "pa-zoomslider-knob", this._track);

    this._btnOut = L.DomUtil.create("a", "pa-zoomslider-out", container);
    this._btnOut.setAttribute("href", "#");
    this._btnOut.setAttribute("role", "button");
    this._btnOut.setAttribute("aria-label", this._zoomOutTitle);
    this._btnOut.dataset.tooltip = this._zoomOutTitle;
    this._btnOut.textContent = "−";

    L.DomEvent.on(this._btnIn, "click", (e) => {
      L.DomEvent.preventDefault(e);
      map.zoomIn();
    });

    L.DomEvent.on(this._btnOut, "click", (e) => {
      L.DomEvent.preventDefault(e);
      map.zoomOut();
    });

    L.DomEvent.on(this._knob, "click", L.DomEvent.stopPropagation);

    L.DomEvent.on(this._track, "click", (e) => {
      const rect = this._track!.getBoundingClientRect();
      const y = (e as MouseEvent).clientY - rect.top;
      map.setZoom(map.getMaxZoom() - y / this._stepHeight);
    });

    L.DomEvent.on(this._knob, "mousedown", (e) => {
      L.DomEvent.preventDefault(e);
      const startY = (e as MouseEvent).clientY;
      const startZoom = map.getZoom();

      const onMouseMove = (e: MouseEvent) => {
        const newZoom = startZoom - (e.clientY - startY) / this._stepHeight;
        map.setZoom(Math.max(map.getMinZoom(), Math.min(map.getMaxZoom(), newZoom)));
      };

      const onMouseUp = () => {
        document.removeEventListener("mousemove", onMouseMove);
        document.removeEventListener("mouseup", onMouseUp);
      };

      document.addEventListener("mousemove", onMouseMove);
      document.addEventListener("mouseup", onMouseUp);
    });

    map.on("zoomend zoomlevelschange", this._update, this);
    this._update();

    return container;
  }

  onRemove(map: L.Map): void {
    map.off("zoomend zoomlevelschange", this._update, this);
    this._map = null;
    this._track = null;
    this._knob = null;
    this._btnIn = null;
    this._btnOut = null;
  }

  private _update(): void {
    if (!this._map || !this._track || !this._knob || !this._btnIn || !this._btnOut) return;
    const min = this._map.getMinZoom();
    const max = this._map.getMaxZoom();
    const zoom = this._map.getZoom();

    this._track.style.height = `${(max - min) * this._stepHeight}px`;
    this._knob.style.top = `${(max - zoom) * this._stepHeight - KNOB_HEIGHT / 2}px`;

    this._btnIn.classList.toggle("leaflet-disabled", zoom >= max);
    this._btnOut.classList.toggle("leaflet-disabled", zoom <= min);
  }
}
