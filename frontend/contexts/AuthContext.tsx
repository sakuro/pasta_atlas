import { createContext, createResource, createMemo, createEffect, useContext, ParentComponent, Accessor } from "solid-js";
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

  const [authData, { refetch, mutate }] = createResource<AuthResponse>(async () => {
    try {
      const res = await fetch("/api/v1/auth/current");
      if (!res.ok) return guestAuth;
      return await res.json() as AuthResponse;
    } catch {
      return guestAuth;
    }
  });

  createEffect(() => {
    const data = authData();
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
    mutate({ ...data, user: { ...data.user, ...patch } });
  };

  return (
    <AuthContext.Provider value={{ currentUser, refetch, updateCurrentUser }}>
      {props.children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
};
