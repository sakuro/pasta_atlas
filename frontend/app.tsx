import "bulma/css/bulma.css";
import "@fortawesome/fontawesome-free/css/fontawesome.css";
import "@fortawesome/fontawesome-free/css/solid.css";
import "@fortawesome/fontawesome-free/css/brands.css";
import "../app/assets/css/app.css";
import "./l10n";

import { render } from "solid-js/web";
import { Router, Route } from "@solidjs/router";
import { AuthProvider } from "./contexts/AuthContext";
import { ToastProvider } from "./contexts/ToastContext";
import { AppLayout } from "./layout/AppLayout";
import { MapsIndexPage } from "./pages/MapsIndexPage";
import { MapViewerPage } from "./pages/MapViewerPage";
import { UserPage } from "./pages/UserPage";
import { RegistrationPage } from "./pages/RegistrationPage";
import { StaticPage } from "./pages/StaticPage";

const mountEl = document.getElementById("app");
if (mountEl) {
  render(
    () => (
      <AuthProvider>
        <ToastProvider>
          <Router root={AppLayout}>
            <Route path="/" component={MapsIndexPage} />
            <Route path="/:at_user_name/maps/:ulid" component={MapViewerPage} />
            <Route path="/auth/register" component={RegistrationPage} />
            <Route path="/about" component={() => <StaticPage slug="about" />} />
            <Route path="/privacy" component={() => <StaticPage slug="privacy" />} />
            <Route path="/terms" component={() => <StaticPage slug="terms" />} />
            <Route path="/:at_user_name" component={UserPage} />
          </Router>
        </ToastProvider>
      </AuthProvider>
    ),
    mountEl
  );
}
