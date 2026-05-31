import { createSignal, Show } from "solid-js";
import { A, RouteSectionProps } from "@solidjs/router";
import { NavbarEnd } from "../islands/navbar_end/NavbarEnd";
import { Footer } from "../islands/footer/Footer";
import { UploadModal } from "../islands/upload_modal/UploadModal";
import { useAuth } from "../contexts/AuthContext";
import logoSrc from "../../app/assets/images/layer8.png";

export const AppLayout = (props: RouteSectionProps) => {
  const [menuActive, setMenuActive] = createSignal(false);
  const { currentUser } = useAuth();
  const user = () => currentUser();

  return (
    <>
      <nav class="navbar" role="navigation" aria-label="main navigation">
        <div class="navbar-brand">
          <A class="navbar-item" href="/">
            <strong data-l10n-id="app-name" />
          </A>
          <div class="navbar-item">
            <Show when={user() !== undefined}>
              <UploadModal isGuest={user() === null} />
            </Show>
          </div>
          <a
            role="button"
            class={`navbar-burger${menuActive() ? " is-active" : ""}`}
            aria-label="menu"
            aria-expanded={menuActive()}
            onClick={() => setMenuActive(v => !v)}
          >
            <span aria-hidden="true" />
            <span aria-hidden="true" />
            <span aria-hidden="true" />
            <span aria-hidden="true" />
          </a>
        </div>
        <div class={`navbar-menu${menuActive() ? " is-active" : ""}`}>
          <div class="navbar-end">
            <Show when={user() !== undefined}>
              <NavbarEnd
                userName={user()?.name ?? ""}
                displayName={user()?.display_name ?? ""}
                avatarUrl={user()?.avatar_url ?? ""}
                userPath={user() ? `/@${user()!.name}` : ""}
                logoutPath="/auth/session"
                csrfToken={document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? ""}
                omniauthToken={document.querySelector<HTMLMetaElement>('meta[name="omniauth-token"]')?.content ?? ""}
              />
            </Show>
          </div>
        </div>
      </nav>
      <Show when={user() !== undefined} fallback={
        <div class="has-text-centered py-6">
          <span class="icon is-large"><i class="fa-solid fa-spinner fa-spin fa-2x" /></span>
        </div>
      }>
        {props.children}
      </Show>
      <footer class="footer">
        <Footer
          logoSrc={logoSrc}
          aboutPath="/about"
          privacyPolicyPath="/privacy"
          termsOfServicePath="/terms"
        />
      </footer>
    </>
  );
};
