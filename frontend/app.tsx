import "bulma/css/bulma.css";
import "@fortawesome/fontawesome-free/css/fontawesome.css";
import "@fortawesome/fontawesome-free/css/solid.css";
import "@fortawesome/fontawesome-free/css/brands.css";
import "../app/assets/css/app.css";
import "./lib/l10n";

import { createEffect } from "solid-js";
import { render } from "@solidjs/web";
import { createRouter } from "@solidjs/router";
import { AuthProvider } from "./contexts/AuthContext";
import { ToastProvider } from "./contexts/ToastContext";
import { AppLayout } from "./layout/AppLayout";
import { lang } from "./lib/display-settings";
import { MapsIndexPage } from "./pages/MapsIndexPage";
import { MapViewerPage } from "./pages/MapViewerPage";
import { NotFoundPage } from "./pages/NotFoundPage";
import { UserPage } from "./pages/UserPage";
import { RegistrationPage } from "./pages/RegistrationPage";
import { StaticPage } from "./pages/StaticPage";

const Router = createRouter({
  routes: [
    { path: "/", component: MapsIndexPage },
    { path: "/maps/:ulid", component: MapViewerPage },
    { path: "/auth/register", component: RegistrationPage },
    { path: "/about", component: () => <StaticPage slug="about" /> },
    { path: "/privacy", component: () => <StaticPage slug="privacy" /> },
    { path: "/terms", component: () => <StaticPage slug="terms" /> },
    { path: "/:at_user_name", component: UserPage, matchFilters: { at_user_name: /^@/ } },
    { path: "*", component: NotFoundPage },
  ],
});

const App = () => {
  createEffect(
    () => lang(),
    (l) => {
      document.documentElement.lang = l;
    }
  );

  return (
    <AuthProvider>
      <ToastProvider>
        <Router>{(props) => <AppLayout {...props} />}</Router>
      </ToastProvider>
    </AuthProvider>
  );
};

const mountEl = document.getElementById("app");
if (mountEl) {
  render(() => <App />, mountEl);
}
