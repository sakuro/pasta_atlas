import { render } from "solid-js/web";
import { UploadModal } from "./UploadModal";

const mountEl = document.getElementById("upload-modal");
if (mountEl) {
  render(() => <UploadModal />, mountEl);
}
