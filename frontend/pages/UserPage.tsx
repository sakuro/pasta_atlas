import { createEffect, createSignal, Errored, For, isPending, Loading, Show } from "solid-js";
import { useLocation, useParams } from "@solidjs/router";
import { Avatar } from "../components/Avatar";
import { SpinnerBlock } from "../components/SpinnerBlock";
import { ErrorNotification } from "../components/ErrorNotification";
import { UserMapsTab } from "./user/UserMapsTab";
import { UserProfileTab } from "./user/UserProfileTab";
import { UserPreferencesTab } from "./user/UserPreferencesTab";
import { UserCredentialsTab } from "./user/UserCredentialsTab";
import { UserDangerTab } from "./user/UserDangerTab";
import { useAuth } from "../contexts/AuthContext";
import { useToast } from "../contexts/ToastContext";
import { showUser, type UserInfo } from "../lib/api/client";

type UserFetchResult = { status: "ok"; user: UserInfo } | { status: "not_found" };

type TabDef = {
  id: string;
  icon: string;
  labelId: string;
  danger?: true;
};

const MAPS_TAB: TabDef = { id: "tab-recent-maps", icon: "fa-solid fa-map", labelId: "user-tab-maps" };
const OWNER_TABS: TabDef[] = [
  MAPS_TAB,
  { id: "tab-profile", icon: "fa-solid fa-circle-user", labelId: "user-tab-profile" },
  { id: "tab-preferences", icon: "fa-solid fa-gear", labelId: "user-tab-preferences" },
  { id: "tab-credentials", icon: "fa-solid fa-link", labelId: "user-tab-credentials" },
  { id: "tab-danger", icon: "fa-solid fa-triangle-exclamation", labelId: "user-tab-danger", danger: true },
];
const GUEST_TABS: TabDef[] = [MAPS_TAB];

const omniauthToken = (): string =>
  document.querySelector<HTMLMetaElement>('meta[name="omniauth-token"]')?.content ?? "";

export const UserPage = () => {
  const params = useParams();
  const userName = () => (params.at_user_name ?? "").slice(1);
  const { currentUser, updateCurrentUser } = useAuth();
  const { showToast } = useToast();

  // Writable so a profile save can patch the displayed user without refetching.
  const [userData, setUserData] = createSignal(async (): Promise<UserFetchResult> => {
    const { data, error, response } = await showUser({ path: { user_name: userName() } });
    if (response?.status === 404) return { status: "not_found" };
    if (!data) throw new Error(`HTTP ${response?.status}`, { cause: error });
    return { status: "ok", user: data.user };
  });

  const user = () => {
    const d = userData();
    return d.status === "ok" ? d.user : undefined;
  };

  const isOwner = () => {
    const u = currentUser();
    return !!u && u.name === userName();
  };

  const location = useLocation();
  const tabs = () => (isOwner() ? OWNER_TABS : GUEST_TABS);
  const [activeTab, setActiveTab] = createSignal("tab-recent-maps");

  const isAvailableTab = (tabId: string) => tabs().some((t) => t.id === tabId);

  const activateTab = (tabId: string) => {
    if (isAvailableTab(tabId)) setActiveTab(tabId);
  };

  // Tracks both location.hash and tabs() (which depends on isOwner()/currentUser()).
  // When auth resolves and tabs() changes to OWNER_TABS, this effect re-runs and
  // can activate the owner-only tab that was initially rejected.
  createEffect(
    () => {
      const hash = location.hash.slice(1);
      return hash && isAvailableTab(hash) ? hash : null;
    },
    (tabId) => {
      if (tabId) setActiveTab(tabId);
    }
  );

  return (
    <section class="section">
      <Errored fallback={<ErrorNotification l10nId="error-load-failed" />}>
        <Loading fallback={<SpinnerBlock />}>
          <Show when={isPending(() => userData())}>
            <SpinnerBlock />
          </Show>
          <Show when={userData().status === "not_found"}>
            <ErrorNotification l10nId="error-user-not-found" type="warning" />
          </Show>
          <Show when={user()} keyed>
            {(u) => (
              <>
                <div class="container">
                  <div class="level">
                    <div class="level-left">
                      <Avatar url={u.avatar_url} size={64} />
                      <h1 class="title ml-3">{u.display_name}</h1>
                    </div>
                  </div>
                  <p class="subtitle">@{u.name}</p>
                </div>
                <div class="container mt-5">
                  <div class="tabs mb-5">
                    <ul>
                      <For each={tabs()}>
                        {(tab) => (
                          <li class={{ "is-active": activeTab() === tab.id }} onClick={() => activateTab(tab.id)}>
                            <a>
                              <span class="icon-text">
                                <span class={["icon", { "has-text-danger": !!tab.danger }]}>
                                  <i class={tab.icon} />
                                </span>
                                <span data-l10n-id={tab.labelId} />
                              </span>
                            </a>
                          </li>
                        )}
                      </For>
                    </ul>
                  </div>
                </div>
                <div class="container">
                  <Show when={activeTab() === "tab-recent-maps"}>
                    <UserMapsTab userName={u.name} active={() => activeTab() === "tab-recent-maps"} />
                  </Show>
                  <Show when={isOwner() && activeTab() === "tab-profile"}>
                    <UserProfileTab
                      userName={u.name}
                      active={() => activeTab() === "tab-profile"}
                      onSuccess={({ displayName, avatarUrl }) => {
                        showToast("profile-saved");
                        setUserData((prev) =>
                          prev.status === "ok"
                            ? { ...prev, user: { ...prev.user, display_name: displayName, avatar_url: avatarUrl } }
                            : prev
                        );
                        updateCurrentUser({ display_name: displayName, avatar_url: avatarUrl });
                      }}
                      onError={(key) => showToast(key, "danger")}
                    />
                  </Show>
                  <Show when={isOwner() && activeTab() === "tab-preferences"}>
                    <UserPreferencesTab
                      userName={u.name}
                      active={() => activeTab() === "tab-preferences"}
                      onSuccess={() => showToast("preferences-saved")}
                      onError={(key) => showToast(key, "danger")}
                    />
                  </Show>
                  <Show when={isOwner() && activeTab() === "tab-credentials"}>
                    <UserCredentialsTab
                      userName={u.name}
                      omniauthToken={omniauthToken()}
                      active={() => activeTab() === "tab-credentials"}
                      onSuccess={() => showToast("credential-disconnected")}
                      onError={(key) => showToast(key, "danger")}
                    />
                  </Show>
                  <Show when={isOwner() && activeTab() === "tab-danger"}>
                    <UserDangerTab userName={u.name} onError={(key) => showToast(key, "danger")} />
                  </Show>
                </div>
              </>
            )}
          </Show>
        </Loading>
      </Errored>
    </section>
  );
};
