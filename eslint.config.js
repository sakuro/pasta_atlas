import solid from "eslint-plugin-solid/configs/typescript";
import * as tsParser from "@typescript-eslint/parser";

export default [
  {
    files: ["frontend/**/*.{ts,tsx}"],
    ...solid,
    languageOptions: {
      parser: tsParser,
    },
  },
];
