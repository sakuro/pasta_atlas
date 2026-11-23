import { defineConfig } from "@hey-api/openapi-ts";

export default defineConfig({
  input: "openapi.yaml",
  output: "frontend/lib/api/gen",
  plugins: [{ name: "@hey-api/client-fetch", baseUrl: false }, "@hey-api/typescript", "@hey-api/sdk"],
});
