import { Show } from "solid-js";
import "../../l10n";

type Props = {
  actionPath: string;
  csrfToken: string;
  suggestedName: string;
  privacyPolicyPath: string;
  termsOfServicePath: string;
  error: string | null;
};

export const RegistrationForm = (props: Props) => {
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

  return (
    <section class="section">
      <div class="container is-max-tablet">
        <h1 class="title" data-l10n-id="registration-title" />
        <Show when={props.error}>
          <div class="notification is-danger is-light">{props.error}</div>
        </Show>
        <form action={props.actionPath} method="post">
          <input type="hidden" name="_csrf_token" value={props.csrfToken} />
          <input type="hidden" name="timezone" value={timezone} />
          <div class="field">
            <label class="label" for="name">
              <span class="icon-text">
                <span class="icon"><i class="fa-solid fa-id-badge" /></span>
                <span data-l10n-id="registration-username" />
              </span>
            </label>
            <div class="control">
              <input class="input" type="text" id="name" name="name"
                     value={props.suggestedName}
                     pattern="[a-zA-Z0-9][a-zA-Z0-9_\-]{0,37}[a-zA-Z0-9]|[a-zA-Z0-9]"
                     maxlength="39" required autofocus />
            </div>
            <p class="help" data-l10n-id="registration-username-help" />
          </div>
          <div class="field">
            <p>
              <a href={props.privacyPolicyPath} target="_blank" rel="noopener">
                <span data-l10n-id="nav-privacy-policy" />
                <span class="icon is-small"><i class="fa-solid fa-arrow-up-right-from-square" /></span>
              </a>
              {" · "}
              <a href={props.termsOfServicePath} target="_blank" rel="noopener">
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
              <button class="button is-primary" type="submit">
                <span class="icon"><i class="fa-solid fa-user-plus" /></span>
                <span data-l10n-id="registration-submit" />
              </button>
            </div>
          </div>
        </form>
      </div>
    </section>
  );
};
