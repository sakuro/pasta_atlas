import L from "leaflet";
import { renderRichText } from "../../richtext";
import "./markers.css";

const icon = L.divIcon({
  html: `<i class="fa-solid fa-tag"></i>`,
  className: "pa-tag-marker",
  iconSize: [32, 32],
  iconAnchor: [16, 16],
});

export class TagMarker extends L.Marker {
  constructor(latlng: L.LatLng, text: string) {
    super(latlng, { icon });
    this.bindTooltip(renderRichText(text), { permanent: true, direction: "auto" });
  }
}
