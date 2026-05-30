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
        maps_index: "frontend/islands/maps_index/index.tsx",
        share_buttons: "frontend/islands/share_buttons/index.tsx",
        user_maps_tab: "frontend/islands/user_maps_tab/index.tsx",
        user_profile_tab: "frontend/islands/user_profile_tab/index.tsx",
        user_preferences_tab: "frontend/islands/user_preferences_tab/index.tsx",
        user_credentials_tab: "frontend/islands/user_credentials_tab/index.tsx",
        footer: "frontend/islands/footer/index.tsx",
        navbar_end: "frontend/islands/navbar_end/index.tsx",
        user_header: "frontend/islands/user_header/index.tsx",
        user_danger_tab: "frontend/islands/user_danger_tab/index.tsx",
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
