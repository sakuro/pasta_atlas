import { render } from "solid-js/web";
import { UserDangerTab } from "./UserDangerTab";

const mountEl = document.getElementById("tab-danger");
if (mountEl) {
  const userName = mountEl.dataset.userName ?? "";
  const actionPath = mountEl.dataset.actionPath ?? "";
  const csrfToken = mountEl.dataset.csrfToken ?? "";
  render(() => <UserDangerTab userName={userName} actionPath={actionPath} csrfToken={csrfToken} />, mountEl);
}
