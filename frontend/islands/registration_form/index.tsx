import { render } from "solid-js/web";
import { RegistrationForm } from "./RegistrationForm";

const mountEl = document.getElementById("registration-form");
if (mountEl) {
  const { actionPath, csrfToken, suggestedName, privacyPolicyPath, termsOfServicePath, error } = mountEl.dataset;
  render(() => <RegistrationForm
    actionPath={actionPath!}
    csrfToken={csrfToken!}
    suggestedName={suggestedName ?? ""}
    privacyPolicyPath={privacyPolicyPath!}
    termsOfServicePath={termsOfServicePath!}
    error={error ?? null}
  />, mountEl);
}
