import { defineConfig } from "vitest/config";
import solid from "vite-plugin-solid";

export default defineConfig({
  plugins: [solid()],
  publicDir: false,
  base: "/assets/",
  build: {
    assetsInlineLimit: 0,
    manifest: true,
    outDir: "public/assets",
    emptyOutDir: true,
    rollupOptions: {
      input: {
        app: "frontend/app.tsx",
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
