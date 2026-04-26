import { defineConfig } from "vitest/config";
import solid from "vite-plugin-solid";

export default defineConfig({
  plugins: [solid()],
  build: {
    outDir: "public/islands",
    emptyOutDir: true,
    rollupOptions: {
      input: {
        map_viewer: "frontend/islands/map_viewer/index.tsx",
        upload_modal: "frontend/islands/upload_modal/index.tsx",
      },
    },
  },
  test: {
    environment: "jsdom",
  },
});
