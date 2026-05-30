import { render } from "solid-js/web";
import { UserHeader } from "./UserHeader";

const mountEl = document.getElementById("user-header");
if (mountEl) {
  const userName = mountEl.dataset.userName ?? "";
  const displayName = mountEl.dataset.displayName ?? "";
  const avatarUrl = mountEl.dataset.avatarUrl ?? "";
  const isOwner = mountEl.dataset.isOwner === "true";
  render(() => <UserHeader userName={userName} displayName={displayName} avatarUrl={avatarUrl} isOwner={isOwner} />, mountEl);
}
