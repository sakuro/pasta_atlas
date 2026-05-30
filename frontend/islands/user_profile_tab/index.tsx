import { createSignal } from "solid-js";
import { render } from "solid-js/web";
import { UserProfileTab } from "./UserProfileTab";

const mountEl = document.getElementById("tab-profile");
if (mountEl) {
  const userName = mountEl.dataset.userName ?? "";
  const [active, setActive] = createSignal(!mountEl.classList.contains("is-hidden"));

  const observer = new MutationObserver(() => {
    if (!mountEl.classList.contains("is-hidden")) {
      setActive(true);
      observer.disconnect();
    }
  });
  observer.observe(mountEl, { attributes: true, attributeFilter: ["class"] });

  render(() => <UserProfileTab userName={userName} active={active} />, mountEl);
}
