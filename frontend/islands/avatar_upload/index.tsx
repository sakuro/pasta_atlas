import { render } from "solid-js/web";
import { AvatarUpload } from "./AvatarUpload";

const mountEl = document.getElementById("avatar-upload");
if (mountEl) {
  const form = mountEl.closest<HTMLFormElement>("form");
  const currentAvatarUrl = mountEl.dataset.currentAvatarUrl || null;
  const userName = mountEl.dataset.userName ?? "";
  render(() => <AvatarUpload currentAvatarUrl={currentAvatarUrl} userName={userName} form={form} />, mountEl);
}
