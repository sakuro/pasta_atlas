import { createSignal } from "solid-js";
import { deleteUser } from "../../lib/api/client";
import "../../lib/l10n";

export const UserDangerTab = (props: { userName: string; onError?: (msgKey: string) => void }) => {
  const [confirmValue, setConfirmValue] = createSignal("");
  const [submitting, setSubmitting] = createSignal(false);

  const handleSubmit = async (e: SubmitEvent) => {
    e.preventDefault();
    if (confirmValue() !== props.userName) return;
    setSubmitting(true);
    try {
      const { data } = await deleteUser({
        path: { user_name: props.userName },
        body: { confirm_user_name: confirmValue() },
      });
      if (data) {
        // The server clears the session; reload so the page gets a fresh CSRF token.
        window.location.assign(data.redirect_to);
      } else {
        props.onError?.("error-unknown");
      }
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <>
      <p class="mb-3" data-l10n-id="account-delete-warning" />
      <form onSubmit={(e) => void handleSubmit(e)}>
        <div class="field">
          <label class="label" for="confirm-user-name" data-l10n-id="account-delete-confirm-label" />
          <div class="field has-addons">
            <p class="control">
              <span class="button is-static">@</span>
            </p>
            <div class="control is-expanded">
              <input
                class="input"
                type="text"
                id="confirm-user-name"
                name="confirm_user_name"
                autocomplete="off"
                placeholder={props.userName}
                onInput={(e) => setConfirmValue(e.currentTarget.value)}
              />
            </div>
          </div>
        </div>
        <div class="field">
          <div class="control">
            <button class="button is-danger" type="submit" disabled={confirmValue() !== props.userName || submitting()}>
              <span class="icon">
                <i class="fa-solid fa-trash" />
              </span>
              <span data-l10n-id="account-delete-button" />
            </button>
          </div>
        </div>
      </form>
    </>
  );
};
