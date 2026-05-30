import { render } from "solid-js/web";
import { NavbarEnd } from "./NavbarEnd";

const mountEl = document.getElementById("navbar-end");
if (mountEl) {
  const userName = mountEl.dataset.userName ?? "";
  const displayName = mountEl.dataset.displayName ?? "";
  const avatarUrl = mountEl.dataset.avatarUrl ?? "";
  const userPath = mountEl.dataset.userPath ?? "";
  const logoutPath = mountEl.dataset.logoutPath ?? "";
  const csrfToken = mountEl.dataset.csrfToken ?? "";
  const omniauthToken = mountEl.dataset.omniauthToken ?? "";
  render(
    () => <NavbarEnd
      userName={userName}
      displayName={displayName}
      avatarUrl={avatarUrl}
      userPath={userPath}
      logoutPath={logoutPath}
      csrfToken={csrfToken}
      omniauthToken={omniauthToken}
    />,
    mountEl
  );
}
