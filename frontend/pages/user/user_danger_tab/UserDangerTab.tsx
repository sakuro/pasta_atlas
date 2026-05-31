import { createSignal } from "solid-js";
import { useNavigate } from "@solidjs/router";
import "../../../lib/l10n";

const csrfToken = (): string =>
  document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? "";

export const UserDangerTab = (props: {
  userName: string;
  onError?: (msgKey: string) => void;
}) => {
  const navigate = useNavigate();
  const [confirmValue, setConfirmValue] = createSignal("");
  const [submitting, setSubmitting] = createSignal(false);

  const handleSubmit = async (e: SubmitEvent) => {
    e.preventDefault();
    if (confirmValue() !== props.userName) return;
    setSubmitting(true);
    try {
      const res = await fetch(`/api/v1/users/${props.userName}`, {
        method: "DELETE",
        headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken() },
        body: JSON.stringify({ user_name: props.userName, confirm_user_name: confirmValue() }),
      });
      if (res.ok) {
        navigate("/");
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
          <div class="control">
            <input
              class="input"
              type="text"
              id="confirm-user-name"
              name="confirm_user_name"
              autocomplete="off"
              onInput={(e) => setConfirmValue(e.currentTarget.value)}
            />
          </div>
        </div>
        <div class="field">
          <div class="control">
            <button
              class="button is-danger"
              type="submit"
              disabled={confirmValue() !== props.userName || submitting()}
            >
              <span class="icon"><i class="fa-solid fa-trash" /></span>
              <span data-l10n-id="account-delete-button" />
            </button>
          </div>
        </div>
      </form>
    </>
  );
};
