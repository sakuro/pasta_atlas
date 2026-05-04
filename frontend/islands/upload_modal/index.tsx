import { render } from "solid-js/web";
import { UploadModal } from "./UploadModal";

const mountEl = document.getElementById("upload-modal");
if (mountEl) {
  const isGuest = mountEl.dataset.guest === "true";
  render(() => <UploadModal isGuest={isGuest} />, mountEl);
}
