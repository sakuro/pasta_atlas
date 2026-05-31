import { Show } from "solid-js";
import { Avatar } from "../../components/Avatar";
import "../../l10n";

type Props = {
  userName: string;
  displayName: string;
  avatarUrl: string;
  userPath: string;
  logoutPath: string;
  csrfToken: string;
  omniauthToken: string;
};

type UserMenuProps = Omit<Props, "omniauthToken">;

const UserMenu = (props: UserMenuProps) => (
  <div class="navbar-item has-dropdown is-hoverable">
    <a class="navbar-link">
      <Avatar url={props.avatarUrl || null} size={24} />
      <span class="ml-2">{props.displayName}</span>
    </a>
    <div class="navbar-dropdown is-right">
      <a class="navbar-item" href={`${props.userPath}#tab-recent-maps`}>
        <span class="icon"><i class="fa-solid fa-map" /></span>
        <span data-l10n-id="user-tab-maps" />
      </a>
      <a class="navbar-item" href={`${props.userPath}#tab-profile`}>
        <span class="icon"><i class="fa-solid fa-circle-user" /></span>
        <span data-l10n-id="user-tab-profile" />
      </a>
      <a class="navbar-item" href={`${props.userPath}#tab-preferences`}>
        <span class="icon"><i class="fa-solid fa-gear" /></span>
        <span data-l10n-id="user-tab-preferences" />
      </a>
      <a class="navbar-item" href={`${props.userPath}#tab-credentials`}>
        <span class="icon"><i class="fa-solid fa-link" /></span>
        <span data-l10n-id="user-tab-credentials" />
      </a>
      <hr class="navbar-divider" />
      <form action={props.logoutPath} method="post">
        <input type="hidden" name="_method" value="delete" />
        <input type="hidden" name="_csrf_token" value={props.csrfToken} />
        <button class="navbar-item" type="submit">
          <span class="icon"><i class="fa-solid fa-arrow-right-from-bracket" /></span>
          <span data-l10n-id="nav-log-out" />
        </button>
      </form>
    </div>
  </div>
);

const LoginMenu = (props: { omniauthToken: string }) => (
  <div class="navbar-item has-dropdown is-hoverable">
    <a class="navbar-link">
      <span class="icon"><i class="fa-solid fa-arrow-right-to-bracket" /></span>
      <span data-l10n-id="nav-log-in" />
    </a>
    <div class="navbar-dropdown is-right">
      <form action="/auth/discord" method="post">
        <input type="hidden" name="authenticity_token" value={props.omniauthToken} />
        <button class="navbar-item" type="submit">
          <span class="icon"><i class="fa-brands fa-discord" /></span>
          <span data-l10n-id="nav-log-in-discord" />
        </button>
      </form>
      <hr class="navbar-divider" />
      <form action="/auth/github" method="post">
        <input type="hidden" name="authenticity_token" value={props.omniauthToken} />
        <button class="navbar-item" type="submit">
          <span class="icon"><i class="fa-brands fa-github" /></span>
          <span data-l10n-id="nav-log-in-github" />
        </button>
      </form>
      <hr class="navbar-divider" />
      <form action="/auth/steam" method="post">
        <input type="hidden" name="authenticity_token" value={props.omniauthToken} />
        <button class="navbar-item" type="submit">
          <span class="icon"><i class="fa-brands fa-steam" /></span>
          <span data-l10n-id="nav-log-in-steam" />
        </button>
      </form>
    </div>
  </div>
);

export const NavAuthMenu = (props: Props) => (
  <Show
    when={props.userName}
    fallback={<LoginMenu omniauthToken={props.omniauthToken} />}
  >
    <UserMenu
      userName={props.userName}
      displayName={props.displayName}
      avatarUrl={props.avatarUrl}
      userPath={props.userPath}
      logoutPath={props.logoutPath}
      csrfToken={props.csrfToken}
    />
  </Show>
);
