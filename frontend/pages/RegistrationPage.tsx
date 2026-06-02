import { createResource, createSignal, Show } from "solid-js";
import { useNavigate } from "@solidjs/router";
import { useAuth } from "../contexts/AuthContext";
import { Spinner } from "../components/Spinner";

type PendingAuth = {
  provider: string;
  login_name: string;
};

const csrfToken = (): string =>
  document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? "";

export const RegistrationPage = () => {
  const navigate = useNavigate();
  const { refetch } = useAuth();
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

  const [pending] = createResource<PendingAuth | null>(async () => {
    const res = await fetch("/api/v1/auth/registration");
    if (res.status === 401) {
      navigate("/");
      return null;
    }
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return res.json() as Promise<PendingAuth>;
  });

  const [submitting, setSubmitting] = createSignal(false);
  const [error, setError] = createSignal<string | null>(null);

  const handleSubmit = async (e: SubmitEvent) => {
    e.preventDefault();
    const form = e.currentTarget as HTMLFormElement;
    const formData = new FormData(form);
    setSubmitting(true);
    setError(null);
    try {
      const res = await fetch("/auth/register", {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        body: JSON.stringify({
          name: formData.get("name") as string,
          timezone,
          terms: formData.get("terms") as string,
        }),
      });
      if (res.ok) {
        refetch();
        navigate("/");
      } else {
        const json = await res.json() as { error?: string };
        setError(json.error ?? "error-unknown");
      }
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <section class="section">
      <Show when={pending.loading}>
        <div class="has-text-centered py-5">
          <Spinner />
        </div>
      </Show>
      <Show when={pending.error}>
        <div class="notification is-danger is-light" data-l10n-id="error-load-failed" />
      </Show>
      <Show when={pending()} keyed>
        {(auth) => {
          const [nameValue, setNameValue] = createSignal(auth.login_name);
          return (
          <div class="container is-max-tablet">
            <h1 class="title" data-l10n-id="registration-title" />
            <Show when={error()}>
              {(errKey) => <div class="notification is-danger is-light" data-l10n-id={errKey()} />}
            </Show>
            <form onSubmit={(e) => void handleSubmit(e)}>
              <div class="field">
                <label class="label" for="name">
                  <span class="icon-text">
                    <span class="icon"><i class="fa-solid fa-id-badge" /></span>
                    <span data-l10n-id="registration-username" />
                  </span>
                </label>
                <div class="control">
                  <input
                    class="input"
                    type="text"
                    id="name"
                    name="name"
                    value={nameValue()}
                    onInput={(e) => setNameValue(e.currentTarget.value)}
                    pattern="[a-zA-Z0-9][a-zA-Z0-9_\-]{0,13}[a-zA-Z0-9]|[a-zA-Z0-9]"
                    maxlength="15"
                    required
                    autofocus
                  />
                </div>
                <div class="is-flex is-justify-content-space-between">
                  <p class="help" data-l10n-id="registration-username-help" />
                  <p class={`help ${nameValue().length >= 15 ? "has-text-danger" : ""}`}>
                    {nameValue().length} / 15
                  </p>
                </div>
              </div>
              <div class="field">
                <p>
                  <a href="/privacy" target="_blank" rel="noopener">
                    <span data-l10n-id="nav-privacy-policy" />
                    <span class="icon is-small"><i class="fa-solid fa-arrow-up-right-from-square" /></span>
                  </a>
                  {" · "}
                  <a href="/terms" target="_blank" rel="noopener">
                    <span data-l10n-id="nav-terms-of-service" />
                    <span class="icon is-small"><i class="fa-solid fa-arrow-up-right-from-square" /></span>
                  </a>
                </p>
                <div class="control">
                  <label class="checkbox">
                    <input type="checkbox" name="terms" value="1" required />
                    {" "}<span data-l10n-id="registration-terms-agree" />
                  </label>
                </div>
              </div>
              <div class="field">
                <div class="control">
                  <button class="button is-primary" type="submit" disabled={submitting()}>
                    <span class="icon"><i class="fa-solid fa-user-plus" /></span>
                    <span data-l10n-id="registration-submit" />
                  </button>
                </div>
              </div>
            </form>
          </div>
          );
        }}
      </Show>
    </section>
  );
};
