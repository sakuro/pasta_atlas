import "bulma/css/bulma.css";
import "@fortawesome/fontawesome-free/css/fontawesome.css";
import "@fortawesome/fontawesome-free/css/solid.css";
import "@fortawesome/fontawesome-free/css/brands.css";
import "../css/app.css";

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
