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

const activateTabByHash = (hash: string) => {
  if (hash) document.querySelector<HTMLElement>(`[data-target="${hash}"]`)?.click();
};

activateTabByHash(document.documentElement.dataset.pendingTab ?? location.hash.slice(1));

window.addEventListener("hashchange", () => activateTabByHash(location.hash.slice(1)));

const confirmInput = document.getElementById("confirm_user_name") as HTMLInputElement | null;
const deleteButton = document.getElementById("delete-account-button") as HTMLButtonElement | null;
if (confirmInput && deleteButton) {
  const expectedUsername = confirmInput.dataset.confirmUsername ?? "";
  confirmInput.addEventListener("input", () => {
    deleteButton.disabled = confirmInput.value !== expectedUsername;
  });
}

