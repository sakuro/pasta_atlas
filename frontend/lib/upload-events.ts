import { createSignal } from "solid-js";

// The upload modal lives in the layout, apart from the pages that list generations.
// Pages read this counter to refetch what an upload has just changed.
const [uploadsCompleted, setUploadsCompleted] = createSignal(0);

export { uploadsCompleted };
export const notifyUploadCompleted = (): void => {
  setUploadsCompleted((n) => n + 1);
};
