import { createSignal } from "solid-js";
import "../../l10n";

type Props = {
  userName: string;
  actionPath: string;
  csrfToken: string;
};

export const UserDangerTab = (props: Props) => {
  const [confirmValue, setConfirmValue] = createSignal("");

  return (
    <>
      <p class="mb-3" data-l10n-id="account-delete-warning" />
      <form action={props.actionPath} method="post">
        <input type="hidden" name="_method" value="delete" />
        <input type="hidden" name="_csrf_token" value={props.csrfToken} />
        <input type="hidden" name="user_name" value={props.userName} />
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
            <button class="button is-danger" type="submit" disabled={confirmValue() !== props.userName}>
              <span class="icon"><i class="fa-solid fa-trash" /></span>
              <span data-l10n-id="account-delete-button" />
            </button>
          </div>
        </div>
      </form>
    </>
  );
};
