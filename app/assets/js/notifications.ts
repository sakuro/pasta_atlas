document.querySelectorAll<HTMLElement>(".notification > .delete").forEach((btn) => {
  btn.addEventListener("click", () => {
    btn.closest(".notification")?.parentElement?.remove();
  });
});
