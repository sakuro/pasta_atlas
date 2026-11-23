import solid from "eslint-plugin-solid/configs/v2";
import * as tsParser from "@typescript-eslint/parser";

export default [
  { ignores: ["frontend/lib/api/gen/"] },
  {
    files: ["frontend/**/*.{ts,tsx}"],
    ...solid,
    languageOptions: {
      parser: tsParser,
    },
  },
];
