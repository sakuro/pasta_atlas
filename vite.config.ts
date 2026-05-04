import { defineConfig } from "vitest/config";
import solid from "vite-plugin-solid";

export default defineConfig({
  plugins: [solid()],
  publicDir: false,
  base: "/assets/islands/",
  build: {
    assetsInlineLimit: 0,
    manifest: true,
    outDir: "public/assets/islands",
    emptyOutDir: true,
    rollupOptions: {
      input: {
        map_viewer: "frontend/islands/map_viewer/index.tsx",
        upload_modal: "frontend/islands/upload_modal/index.tsx",
        avatar_upload: "frontend/islands/avatar_upload/index.tsx",
        map_info_button: "frontend/islands/map_info_button/index.tsx",
        share_buttons: "frontend/islands/share_buttons/index.tsx",
      },
      output: {
        entryFileNames: "[name]-[hash].js",
        chunkFileNames: "[name]-[hash].js",
        assetFileNames: "[name]-[hash][extname]",
      },
    },
  },
  test: {
    environment: "jsdom",
  },
});
