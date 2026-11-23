import {
  createContext,
  createSignal,
  createMemo,
  createEffect,
  refresh,
  useContext,
  ParentComponent,
  Accessor,
} from "solid-js";
import { applyPreferences } from "../lib/display-settings";
import { l10n, connectRoot } from "../lib/l10n";
import { getCurrentAuth, type GetCurrentAuthResponse, type UserInfo } from "../lib/api/client";

type AuthContextValue = {
  currentUser: Accessor<UserInfo | null | undefined>;
  refetch: () => void;
  updateCurrentUser: (patch: Partial<UserInfo>) => void;
};

const AuthContext = createContext<AuthContextValue>();

export const AuthProvider: ParentComponent = (props) => {
  const guestAuth: GetCurrentAuthResponse = {
    user: null,
    preferences: { locale: null, timezone: "UTC", relative_timestamps: false },
  };

  // A writable memo so updateCurrentUser can patch the fetched value locally.
  // loadingValue keeps the first fetch from suspending: consumers treat `undefined`
  // as "not known yet" and render their own placeholder instead of a Loading boundary.
  const [authData, setAuthData] = createSignal<GetCurrentAuthResponse | undefined>(
    async () => {
      const { data } = await getCurrentAuth();
      return data ?? guestAuth;
    },
    { loadingValue: undefined }
  );

  const refetch = () => {
    void refresh(authData);
  };

  createEffect(
    () => authData(),
    (data) => {
      if (data === undefined) return;
      applyPreferences(data.preferences.locale, data.preferences.timezone, data.preferences.relative_timestamps);
      connectRoot();
      l10n.onChange();
    }
  );

  const currentUser = createMemo<UserInfo | null | undefined>(() => {
    const data = authData();
    if (data === undefined) return undefined;
    return data.user;
  });

  const updateCurrentUser = (patch: Partial<UserInfo>) => {
    const data = authData();
    if (!data?.user) return;
    setAuthData({ ...data, user: { ...data.user, ...patch } });
  };

  return <AuthContext value={{ currentUser, refetch, updateCurrentUser }}>{props.children}</AuthContext>;
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
};
