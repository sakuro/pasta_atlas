import "bulma/css/bulma.css";
import "@fortawesome/fontawesome-free/css/fontawesome.css";
import "@fortawesome/fontawesome-free/css/solid.css";
import "@fortawesome/fontawesome-free/css/brands.css";
import "../css/app.css";
import "./navbar";

document.querySelectorAll<HTMLElement>(".notification > .delete").forEach((btn) => {
  btn.addEventListener("click", () => {
    btn.closest(".notification")?.parentElement?.remove();
  });
});



