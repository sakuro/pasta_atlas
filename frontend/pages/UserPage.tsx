import { createEffect, createResource, createSignal, For, Show } from "solid-js";
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

type UserData = {
  name: string;
  display_name: string;
  avatar_url: string | null;
};

type UserFetchResult =
  | { status: "ok"; user: UserData }
  | { status: "not_found" }
  | { status: "forbidden" };

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

  const [userData, { mutate: mutateUser }] = createResource(userName, async (name): Promise<UserFetchResult> => {
    const res = await fetch(`/api/v1/users/${name}`);
    if (res.status === 404) return { status: "not_found" };
    if (res.status === 403) return { status: "forbidden" };
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const json = await res.json() as { user: UserData };
    return { status: "ok", user: json.user };
  });

  const user = () => {
    if (userData.error) return undefined;
    const d = userData();
    return d?.status === "ok" ? d.user : undefined;
  };

  const isOwner = () => {
    const u = currentUser();
    return !!u && u.name === userName();
  };

  const location = useLocation();
  const tabs = () => (isOwner() ? OWNER_TABS : GUEST_TABS);
  const [activeTab, setActiveTab] = createSignal("tab-recent-maps");

  const activateTab = (tabId: string) => {
    if (!tabs().some((t) => t.id === tabId)) return;
    setActiveTab(tabId);
  };

  // Tracks both location.hash and tabs() (which depends on isOwner()/currentUser()).
  // When auth resolves and tabs() changes to OWNER_TABS, this effect re-runs and
  // can activate the owner-only tab that was initially rejected.
  createEffect(() => {
    const hash = location.hash.slice(1);
    if (hash) activateTab(hash);
  });

  return (
    <section class="section">
      <Show when={userData.loading}>
        <SpinnerBlock />
      </Show>
      <Show when={userData.error}>
        <ErrorNotification l10nId="error-load-failed" />
      </Show>
      <Show when={userData.state === "ready" && userData()?.status === "not_found"}>
        <ErrorNotification l10nId="error-user-not-found" type="warning" />
      </Show>
      <Show when={userData.state === "ready" && userData()?.status === "forbidden"}>
        <ErrorNotification l10nId="error-user-forbidden" type="warning" />
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
                      <li
                        classList={{ "is-active": activeTab() === tab.id }}
                        onClick={() => activateTab(tab.id)}
                      >
                        <a>
                          <span class="icon-text">
                            <span classList={{ icon: true, "has-text-danger": !!tab.danger }}>
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
                    mutateUser(prev => prev?.status === "ok" ? { ...prev, user: { ...prev.user, display_name: displayName, avatar_url: avatarUrl } } : prev);
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
                <UserDangerTab
                  userName={u.name}
                  onError={(key) => showToast(key, "danger")}
                />
              </Show>
            </div>
          </>
        )}
      </Show>
    </section>
  );
};
