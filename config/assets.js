import * as assets from "hanami-assets";
import fs from "fs";
import path from "path";

await assets.run({
  esbuildOptionsFn: (args, esbuildOptions) => {
    const ftlManifestPlugin = {
      name: "ftl-manifest",
      setup(build) {
        build.onEnd(() => {
          const destDir = path.join(process.cwd(), args.dest);
          const manifestPath = path.join(destDir, "assets.json");
          if (!fs.existsSync(manifestPath)) return;
          const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf-8"));
          const ftlManifest = Object.fromEntries(
            Object.entries(manifest).filter(([key]) => key.endsWith(".ftl"))
          );
          fs.writeFileSync(
            path.join(destDir, "ftl-manifest.json"),
            JSON.stringify(ftlManifest, null, 2)
          );
        });
      },
    };
    esbuildOptions.plugins = [...esbuildOptions.plugins, ftlManifestPlugin];
    return esbuildOptions;
  },
});
