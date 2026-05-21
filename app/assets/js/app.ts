import "bulma/css/bulma.css";
import "@fortawesome/fontawesome-free/css/fontawesome.css";
import "@fortawesome/fontawesome-free/css/solid.css";
import "@fortawesome/fontawesome-free/css/brands.css";
import "../css/app.css";

document.querySelectorAll<HTMLElement>(".notification > .delete").forEach((btn) => {
  btn.addEventListener("click", () => {
    btn.closest(".notification")?.parentElement?.remove();
  });
});

document.querySelectorAll<HTMLElement>(".navbar-item.has-dropdown").forEach((dropdown) => {
  dropdown.querySelector(".navbar-link")?.addEventListener("click", () => {
    dropdown.classList.toggle("is-active");
  });
});

const burger = document.querySelector<HTMLElement>(".navbar-burger");
if (burger?.dataset.target) {
  const menu = document.getElementById(burger.dataset.target);
  burger.addEventListener("click", () => {
    const expanded = burger.getAttribute("aria-expanded") === "true";
    burger.setAttribute("aria-expanded", String(!expanded));
    burger.classList.toggle("is-active");
    menu?.classList.toggle("is-active");
  });
}

document.querySelectorAll<HTMLElement>("[data-tabs]").forEach((tabsEl) => {
  const groupId = tabsEl.dataset.tabs!;
  const panels = document.querySelectorAll<HTMLElement>(`[data-tab-panel="${groupId}"]`);
  tabsEl.querySelectorAll<HTMLElement>("li[data-target]").forEach((tab) => {
    tab.addEventListener("click", () => {
      tabsEl.querySelectorAll("li").forEach((t) => t.classList.remove("is-active"));
      panels.forEach((p) => p.classList.add("is-hidden"));
      tab.classList.add("is-active");
      const target = tab.dataset.target;
      if (target) document.getElementById(target)?.classList.remove("is-hidden");
    });
  });
});

document.querySelectorAll<HTMLAnchorElement>(".tab-edit-link").forEach((link) => {
  link.addEventListener("click", (e) => e.stopPropagation());
});

const initialHash = location.hash.slice(1);
if (initialHash) {
  document.querySelector<HTMLElement>(`[data-target="${initialHash}"]`)?.click();
}

const timezoneInput = document.getElementById("timezone") as HTMLInputElement | null;
if (timezoneInput) {
  timezoneInput.value = Intl.DateTimeFormat().resolvedOptions().timeZone;
}

const tzSelect = document.getElementById("timezone-select") as HTMLSelectElement | null;
const tzTimeEl = document.getElementById("timezone-time");

if (tzSelect && tzTimeEl) {
  const currentTimeInTz = (tz: string): string =>
    new Intl.DateTimeFormat("en", {
      timeZone: tz,
      hour: "2-digit",
      minute: "2-digit",
      hour12: false,
    }).format(new Date());

  const updateTzTime = () => {
    tzTimeEl.textContent = currentTimeInTz(tzSelect.value);
  };

  tzSelect.addEventListener("change", updateTzTime);
  updateTzTime();

  // sync updates to minute boundaries
  const now = new Date();
  setTimeout(() => {
    updateTzTime();
    setInterval(updateTzTime, 60000);
  }, (60 - now.getSeconds()) * 1000 - now.getMilliseconds());
}
