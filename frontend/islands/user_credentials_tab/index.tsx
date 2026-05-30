import { createSignal } from "solid-js";
import { render } from "solid-js/web";
import { UserCredentialsTab } from "./UserCredentialsTab";

const mountEl = document.getElementById("tab-credentials");
if (mountEl) {
  const userName = mountEl.dataset.userName ?? "";
  const omniauthToken = mountEl.dataset.omniauthToken ?? "";
  const [active, setActive] = createSignal(!mountEl.classList.contains("is-hidden"));

  const observer = new MutationObserver(() => {
    if (!mountEl.classList.contains("is-hidden")) {
      setActive(true);
      observer.disconnect();
    }
  });
  observer.observe(mountEl, { attributes: true, attributeFilter: ["class"] });

  render(() => <UserCredentialsTab userName={userName} omniauthToken={omniauthToken} active={active} />, mountEl);
}
