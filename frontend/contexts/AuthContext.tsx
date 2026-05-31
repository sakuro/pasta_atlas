import { createContext, createResource, useContext, ParentComponent, Resource } from "solid-js";

export type CurrentUser = {
  name: string;
  display_name: string;
  avatar_url: string | null;
};

type AuthContextValue = {
  currentUser: Resource<CurrentUser | null>;
  refetch: () => void;
  updateCurrentUser: (patch: Partial<CurrentUser>) => void;
};

const AuthContext = createContext<AuthContextValue>();

export const AuthProvider: ParentComponent = (props) => {
  const [currentUser, { refetch, mutate }] = createResource<CurrentUser | null>(async () => {
    const res = await fetch("/api/v1/auth/current");
    if (!res.ok) return null;
    const data = await res.json() as { user: CurrentUser | null };
    return data.user;
  });

  const updateCurrentUser = (patch: Partial<CurrentUser>) => {
    const current = currentUser();
    if (current) mutate({ ...current, ...patch });
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
