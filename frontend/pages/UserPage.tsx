import { createResource, createSignal, For, onMount, Show } from "solid-js";
import { useParams } from "@solidjs/router";
import { Avatar } from "../components/Avatar";
import { UserMapsTab } from "../components/user_maps_tab/UserMapsTab";
import { UserProfileTab } from "../components/user_profile_tab/UserProfileTab";
import { UserPreferencesTab } from "../components/user_preferences_tab/UserPreferencesTab";
import { UserCredentialsTab } from "../components/user_credentials_tab/UserCredentialsTab";
import { UserDangerTab } from "../components/user_danger_tab/UserDangerTab";
import { useAuth } from "../contexts/AuthContext";
import { useToast } from "../contexts/ToastContext";

type UserData = {
  name: string;
  display_name: string;
  avatar_url: string | null;
};

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

  const [userData, { mutate: mutateUser }] = createResource(userName, async (name) => {
    const res = await fetch(`/api/v1/users/${name}`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const json = await res.json() as { user: UserData };
    return json.user;
  });

  const isOwner = () => {
    const user = currentUser();
    return !!user && user.name === userName();
  };

  const tabs = () => (isOwner() ? OWNER_TABS : GUEST_TABS);
  const [activeTab, setActiveTab] = createSignal("tab-recent-maps");

  const activateTab = (tabId: string) => {
    if (!tabs().some((t) => t.id === tabId)) return;
    setActiveTab(tabId);
  };

  onMount(() => {
    const hash = location.hash.slice(1);
    if (hash) {
      history.replaceState(null, document.title, location.pathname + location.search);
      activateTab(hash);
    }
  });

  return (
    <section class="section">
      <Show when={userData.loading}>
        <div class="has-text-centered py-5">
          <span class="icon"><i class="fa-solid fa-spinner fa-spin" /></span>
        </div>
      </Show>
      <Show when={userData.error}>
        <div class="notification is-danger is-light" />
      </Show>
      <Show when={userData()} keyed>
        {(user) => (
          <>
            <div class="container">
              <div class="level">
                <div class="level-left">
                  <Avatar url={user.avatar_url} size={64} />
                  <h1 class="title ml-3">{user.display_name}</h1>
                </div>
              </div>
              <p class="subtitle">@{user.name}</p>
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
                <UserMapsTab userName={user.name} active={() => activeTab() === "tab-recent-maps"} />
              </Show>
              <Show when={isOwner() && activeTab() === "tab-profile"}>
                <UserProfileTab
                  userName={user.name}
                  active={() => activeTab() === "tab-profile"}
                  onSuccess={({ displayName, avatarUrl }) => {
                    showToast("profile-saved");
                    mutateUser(u => u ? { ...u, display_name: displayName, avatar_url: avatarUrl } : u);
                    updateCurrentUser({ display_name: displayName, avatar_url: avatarUrl });
                  }}
                  onError={(key) => showToast(key, "danger")}
                />
              </Show>
              <Show when={isOwner() && activeTab() === "tab-preferences"}>
                <UserPreferencesTab
                  userName={user.name}
                  active={() => activeTab() === "tab-preferences"}
                  onSuccess={() => showToast("preferences-saved")}
                  onError={(key) => showToast(key, "danger")}
                />
              </Show>
              <Show when={isOwner() && activeTab() === "tab-credentials"}>
                <UserCredentialsTab
                  userName={user.name}
                  omniauthToken={omniauthToken()}
                  active={() => activeTab() === "tab-credentials"}
                  onSuccess={() => showToast("credential-disconnected")}
                  onError={(key) => showToast(key, "danger")}
                />
              </Show>
              <Show when={isOwner() && activeTab() === "tab-danger"}>
                <UserDangerTab
                  userName={user.name}
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
