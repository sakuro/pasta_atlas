import { defineConfig } from "vitest/config";
import solid from "vite-plugin-solid";
import fs from "node:fs";

type ViteManifestEntry = {
  file: string;
  name?: string;
  isEntry?: boolean;
  css?: string[];
};

const hanamiViteEntries = () => ({
  name: "hanami-vite-entries",
  closeBundle() {
    const outDir = "public/assets";
    const viteManifestPath = `${outDir}/.vite/manifest.json`;
    if (!fs.existsSync(viteManifestPath)) return;

    const viteManifest = JSON.parse(
      fs.readFileSync(viteManifestPath, "utf-8")
    ) as Record<string, ViteManifestEntry>;

    const appEntry = Object.values(viteManifest).find(
      (e) => e.isEntry && e.name === "app"
    );
    if (!appEntry) return;

    const entries: Record<string, { url: string }> = {
      "app.js": { url: `/assets/${appEntry.file}` },
    };
    if (appEntry.css?.length) {
      entries["app.css"] = { url: `/assets/${appEntry.css[0]}` };
    }

    fs.writeFileSync(
      `${outDir}/vite-entries.json`,
      JSON.stringify(entries, null, 2)
    );

    const assetsJsonPath = `${outDir}/assets.json`;
    if (fs.existsSync(assetsJsonPath)) {
      const assetsJson = JSON.parse(
        fs.readFileSync(assetsJsonPath, "utf-8")
      ) as Record<string, unknown>;
      Object.assign(assetsJson, entries);
      fs.writeFileSync(assetsJsonPath, JSON.stringify(assetsJson, null, 2));
    }
  },
});

export default defineConfig({
  plugins: [solid(), hanamiViteEntries()],
  publicDir: false,
  base: "/assets/",
  build: {
    assetsInlineLimit: 0,
    manifest: true,
    outDir: "public/assets",
    emptyOutDir: false,
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
