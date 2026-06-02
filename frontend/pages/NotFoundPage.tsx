import { ErrorNotification } from "../components/ErrorNotification";

export const NotFoundPage = () => (
  <section class="section">
    <div class="container">
      <ErrorNotification l10nId="error-page-not-found" type="warning" />
    </div>
  </section>
);
