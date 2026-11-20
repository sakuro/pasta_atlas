import { createContext, createSignal, createMemo, createEffect, refresh, useContext, ParentComponent, Accessor } from "solid-js";
import { applyPreferences } from "../lib/display-settings";
import { l10n, connectRoot } from "../lib/l10n";

export type CurrentUser = {
  name: string;
  display_name: string;
  avatar_url: string | null;
};

type Preferences = {
  locale: string | null;
  timezone: string;
  relative_timestamps: boolean;
};

type AuthResponse = {
  user: CurrentUser | null;
  preferences: Preferences;
};

type AuthContextValue = {
  currentUser: Accessor<CurrentUser | null | undefined>;
  refetch: () => void;
  updateCurrentUser: (patch: Partial<CurrentUser>) => void;
};

const AuthContext = createContext<AuthContextValue>();

export const AuthProvider: ParentComponent = (props) => {
  const guestAuth: AuthResponse = { user: null, preferences: { locale: null, timezone: "UTC", relative_timestamps: false } };

  // A writable memo so updateCurrentUser can patch the fetched value locally.
  // loadingValue keeps the first fetch from suspending: consumers treat `undefined`
  // as "not known yet" and render their own placeholder instead of a Loading boundary.
  const [authData, setAuthData] = createSignal<AuthResponse | undefined>(async () => {
    try {
      const res = await fetch("/api/v1/auth/current");
      if (!res.ok) return guestAuth;
      return await res.json() as AuthResponse;
    } catch {
      return guestAuth;
    }
  }, { loadingValue: undefined });

  const refetch = () => { void refresh(authData); };

  createEffect(() => authData(), (data) => {
    if (data === undefined) return;
    applyPreferences(data.preferences.locale, data.preferences.timezone, data.preferences.relative_timestamps);
    connectRoot();
    l10n.onChange();
  });

  const currentUser = createMemo<CurrentUser | null | undefined>(() => {
    const data = authData();
    if (data === undefined) return undefined;
    return data.user;
  });

  const updateCurrentUser = (patch: Partial<CurrentUser>) => {
    const data = authData();
    if (!data?.user) return;
    setAuthData({ ...data, user: { ...data.user, ...patch } });
  };

  return (
    <AuthContext value={{ currentUser, refetch, updateCurrentUser }}>
      {props.children}
    </AuthContext>
  );
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
};
