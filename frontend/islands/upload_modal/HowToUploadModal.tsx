import { Portal } from "solid-js/web";

export const HowToUploadModal = (props: { onClose: () => void }) => (
  <Portal mount={document.body}>
    <div class="modal is-active">
      <div class="modal-background" onClick={props.onClose} />
      <div class="modal-card" style={{ width: "90vw", "max-width": "700px" }}>
        <header class="modal-card-head">
          <p class="modal-card-title" data-l10n-id="how-to-upload-title" />
          <button class="delete" aria-label="close" onClick={props.onClose} />
        </header>
        <section class="modal-card-body">
          <div class="content">
            <h4 data-l10n-id="how-to-upload-step1-heading" />
            <p data-l10n-id="how-to-upload-step1-body">
              <a data-l10n-name="mapshot-link" href="https://mods.factorio.com/mod/mapshot" target="_blank" rel="noopener noreferrer" />
            </p>

            <h4 data-l10n-id="how-to-upload-step2-heading" />
            <p data-l10n-id="how-to-upload-step2-open-console" />
            <pre><code>/mapshot</code></pre>
            <p data-l10n-id="how-to-upload-step2-wait" />
            <div class="notification is-warning is-light">
              <p data-l10n-id="how-to-upload-achievement-warning" />
            </div>

            <h4 data-l10n-id="how-to-upload-step3-heading" />
            <ol>
              <li data-l10n-id="how-to-upload-step3-click-upload" />
              <li data-l10n-id="how-to-upload-step3-select-folder">
                <code data-l10n-name="filename">mapshot.json</code>
              </li>
              <li data-l10n-id="how-to-upload-step3-confirm" />
              <li data-l10n-id="how-to-upload-step3-view" />
            </ol>

            <div class="notification is-info is-light">
              <p data-l10n-id="how-to-upload-tip" />
            </div>
          </div>
        </section>
        <footer class="modal-card-foot">
          <button class="button" data-l10n-id="how-to-upload-close" onClick={props.onClose} />
        </footer>
      </div>
    </div>
  </Portal>
);
