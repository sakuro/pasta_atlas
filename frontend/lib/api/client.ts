import { client } from "./gen/client.gen";

// requestMapDeletion is answered with a redirect; call it with fetch and redirect: "manual" instead (see MapViewer).
export * from "./gen";

export const csrfToken = (): string =>
  document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? "";

// Error bodies are not validated at runtime, and a status documented without a body makes the
// generated error type unknown, so the key of an { "error": "<key>" } body is read here.
export const errorKey = (error: unknown): string | undefined =>
  typeof error === "object" && error !== null && "error" in error && typeof error.error === "string"
    ? error.error
    : undefined;

// The generated client sends relative URLs; a Request needs an absolute URL outside the browser (Vitest).
client.setConfig({ baseUrl: window.location.origin });

client.interceptors.request.use((request) => {
  request.headers.set("X-CSRF-Token", csrfToken());
  return request;
});
