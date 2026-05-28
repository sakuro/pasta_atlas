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
