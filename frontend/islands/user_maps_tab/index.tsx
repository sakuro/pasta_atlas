import { createSignal } from "solid-js";
import { render } from "solid-js/web";
import { UserMapsTab } from "./UserMapsTab";

const mountEl = document.getElementById("tab-recent-maps");
if (mountEl) {
  const userName = mountEl.dataset.userName ?? "";
  const relativeTimestamps = mountEl.dataset.relativeTimestamps === "true";
  const timezone = mountEl.dataset.viewerTimezone ?? "UTC";
  const [active, setActive] = createSignal(!mountEl.classList.contains("is-hidden"));

  const observer = new MutationObserver(() => {
    if (!mountEl.classList.contains("is-hidden")) {
      setActive(true);
      observer.disconnect();
    }
  });
  observer.observe(mountEl, { attributes: true, attributeFilter: ["class"] });

  render(() => <UserMapsTab userName={userName} active={active} relativeTimestamps={relativeTimestamps} timezone={timezone} />, mountEl);
}
