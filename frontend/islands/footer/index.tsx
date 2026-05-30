import { render } from "solid-js/web";
import { Footer } from "./Footer";

const mountEl = document.getElementById("footer");
if (mountEl) {
  const logoSrc = mountEl.dataset.logoSrc ?? "";
  const aboutPath = mountEl.dataset.aboutPath ?? "";
  const privacyPolicyPath = mountEl.dataset.privacyPolicyPath ?? "";
  const termsOfServicePath = mountEl.dataset.termsOfServicePath ?? "";
  render(() => <Footer logoSrc={logoSrc} aboutPath={aboutPath} privacyPolicyPath={privacyPolicyPath} termsOfServicePath={termsOfServicePath} />, mountEl);
}
