import { createMemo, createSignal, Errored, Loading, onSettled, Show } from "solid-js";
import { useNavigate } from "@solidjs/router";
import { SpinnerBlock } from "../components/SpinnerBlock";
import { ErrorNotification } from "../components/ErrorNotification";
import { errorKey, getPendingRegistration, register } from "../lib/api/client";

const RedirectHome = () => {
  const navigate = useNavigate();
  // Navigating from onSettled keeps the write out of the async computation.
  onSettled(() => {
    navigate("/");
  });
  return null;
};

export const RegistrationPage = () => {
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

  const pending = createMemo(async () => {
    const { data, error, response } = await getPendingRegistration();
    if (response?.status === 403) return null;
    if (!data) throw new Error(`HTTP ${response?.status}`, { cause: error });
    return data;
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
      const { data, error } = await register({
        body: {
          name: formData.get("name") as string,
          timezone,
          terms: formData.has("terms"),
        },
      });
      if (data) {
        // The server clears the session, which invalidates the CSRF token in this page's
        // meta tag. A full page load picks up the new token.
        window.location.assign(data.redirect_to);
      } else {
        setError(errorKey(error) ?? "error-unknown");
      }
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <section class="section">
      <Errored fallback={<ErrorNotification l10nId="error-load-failed" />}>
        <Loading fallback={<SpinnerBlock />}>
          {/* The registration endpoint answers 403 when no OAuth data is pending. */}
          <Show when={pending()} keyed fallback={<RedirectHome />}>
            {(auth) => {
              const [nameValue, setNameValue] = createSignal(auth.login_name);
              return (
                <div class="container is-max-tablet">
                  <h1 class="title" data-l10n-id="registration-title" />
                  <Show when={error()}>{(errKey) => <ErrorNotification l10nId={errKey()} />}</Show>
                  <form onSubmit={(e) => void handleSubmit(e)}>
                    <div class="field">
                      <label class="label" for="name">
                        <span class="icon-text">
                          <span class="icon">
                            <i class="fa-solid fa-id-badge" />
                          </span>
                          <span data-l10n-id="registration-username" />
                        </span>
                      </label>
                      <div class="field has-addons mb-0">
                        <p class="control">
                          <span class="button is-static">@</span>
                        </p>
                        <div class="control is-expanded">
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
                        <div class="control">
                          <span
                            class={[
                              "button is-static",
                              nameValue().length >= 15 ? "has-text-danger" : "has-text-grey-light",
                            ]}
                          >
                            {nameValue().length} / 15
                          </span>
                        </div>
                      </div>
                      <p class="help" data-l10n-id="registration-username-help" />
                    </div>
                    <div class="field">
                      <p>
                        <a href="/privacy" target="_blank" rel="noopener">
                          <span data-l10n-id="nav-privacy-policy" />
                          <span class="icon is-small">
                            <i class="fa-solid fa-arrow-up-right-from-square" />
                          </span>
                        </a>
                        {" · "}
                        <a href="/terms" target="_blank" rel="noopener">
                          <span data-l10n-id="nav-terms-of-service" />
                          <span class="icon is-small">
                            <i class="fa-solid fa-arrow-up-right-from-square" />
                          </span>
                        </a>
                      </p>
                      <div class="control">
                        <label class="checkbox">
                          <input type="checkbox" name="terms" value="1" required />{" "}
                          <span data-l10n-id="registration-terms-agree" />
                        </label>
                      </div>
                    </div>
                    <div class="field">
                      <div class="control">
                        <button class="button is-primary" type="submit" disabled={submitting()}>
                          <span class="icon">
                            <i class="fa-solid fa-user-plus" />
                          </span>
                          <span data-l10n-id="registration-submit" />
                        </button>
                      </div>
                    </div>
                  </form>
                </div>
              );
            }}
          </Show>
        </Loading>
      </Errored>
    </section>
  );
};
