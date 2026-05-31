import "../lib/l10n";

type Props = {
  logoSrc: string;
  aboutPath: string;
  privacyPolicyPath: string;
  termsOfServicePath: string;
};

export const Footer = (props: Props) => (
  <div class="content has-text-centered">
    <p>
      &copy; 2026{" "}
      <img src={props.logoSrc} alt="" class="footer-logo" />{" "}
      <span class="footer-brand">layer<span class="footer-brand-accent">8</span>.works</span>
      {" | "}
      <a href={props.aboutPath} data-l10n-id="nav-about" />
      {" | "}
      <a href={props.privacyPolicyPath} data-l10n-id="nav-privacy-policy" />
      {" | "}
      <a href={props.termsOfServicePath} data-l10n-id="nav-terms-of-service" />
      {" | "}
      <span class="icon-text">
        <span class="icon"><i class="fa-brands fa-github" /></span>
        <span>
          <a href="https://github.com/sakuro/pasta_atlas" target="_blank" rel="noopener">Code</a>
          {" | "}
          <a href="https://github.com/sakuro/pasta_atlas/issues" target="_blank" rel="noopener">Issues</a>
          {" | "}
          <a href="https://github.com/sakuro/pasta_atlas/discussions" target="_blank" rel="noopener">Discussions</a>
        </span>
      </span>
    </p>
  </div>
);
