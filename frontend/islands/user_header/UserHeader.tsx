import { createSignal, For, onMount } from "solid-js";
import { Avatar } from "../../components/Avatar";
import "../../l10n";

type Props = {
  userName: string;
  displayName: string;
  avatarUrl: string;
  isOwner: boolean;
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

export const UserHeader = (props: Props) => {
  const [activeTab, setActiveTab] = createSignal("tab-recent-maps");
  const tabs = () => (props.isOwner ? OWNER_TABS : GUEST_TABS);

  const activateTab = (tabId: string) => {
    if (!tabs().some((t) => t.id === tabId)) return;
    document.querySelectorAll("[data-tab-panel]").forEach((panel) => {
      panel.classList.toggle("is-hidden", panel.id !== tabId);
    });
    setActiveTab(tabId);
  };

  onMount(() => {
    const hash = location.hash.slice(1);
    if (hash) {
      history.replaceState(null, document.title, location.pathname + location.search);
      activateTab(hash);
    }
    window.addEventListener("hashchange", () => {
      const h = location.hash.slice(1);
      if (h) activateTab(h);
    });
  });

  return (
    <>
      <div class="container">
        <div class="level">
          <div class="level-left">
            <Avatar url={props.avatarUrl || null} size={64} />
            <h1 class="title ml-3">{props.displayName || props.userName}</h1>
          </div>
        </div>
        <p class="subtitle">@{props.userName}</p>
      </div>
      <div class="container mt-5">
        <div class="tabs mb-5">
          <ul>
            <For each={tabs()}>
              {(tab) => (
                <li classList={{ "is-active": activeTab() === tab.id }} onClick={() => activateTab(tab.id)}>
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
    </>
  );
};
