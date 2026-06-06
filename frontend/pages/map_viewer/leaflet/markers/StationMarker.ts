import L from "leaflet";
import { renderRichText } from "../../richtext";
import "./markers.css";

const icon = L.divIcon({
  html: `<i class="fa-solid fa-location-dot"></i>`,
  className: "pa-station-marker",
  iconSize: [32, 32],
  iconAnchor: [16, 32],
});

export class StationMarker extends L.Marker {
  constructor(latlng: L.LatLng, name: string) {
    super(latlng, { icon });
    this.bindTooltip(renderRichText(name), { permanent: true, direction: "auto" });
  }
}
