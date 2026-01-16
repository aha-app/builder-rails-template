import pluginJs from "@eslint/js";
import prettierConfig from "eslint-config-prettier/flat";
import importPlugin from "eslint-plugin-import";
import pluginReact from "eslint-plugin-react";
import reactHooks from "eslint-plugin-react-hooks";
import unusedImports from "eslint-plugin-unused-imports";
import globals from "globals";
import tseslint from "typescript-eslint";

// eslint-disable-next-line import/extensions
import inertiaLocal from "./eslint-local-rules/index.js";

/** @type {import('eslint').Linter.Config[]} */
export default [
  { files: ["app/frontend/**/*.{js,mjs,cjs,ts,jsx,tsx}"] },
  { ignores: ["app/frontend/routes/*"] },
  {
    settings: {
      react: {
        version: "detect",
      },
    },
    languageOptions: {
      globals: { ...globals.browser, ...globals.node },
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },
  pluginJs.configs.recommended,
  reactHooks.configs.flat.recommended,
  ...tseslint.configs.stylisticTypeChecked,
  ...tseslint.configs.recommendedTypeChecked,
  pluginReact.configs.flat.recommended,
  pluginReact.configs.flat["jsx-runtime"],
  prettierConfig,
  {
    ...importPlugin.flatConfigs.recommended,
    ...importPlugin.flatConfigs.typescript,
    plugins: {
      ...importPlugin.flatConfigs.recommended.plugins,
      ...importPlugin.flatConfigs.typescript.plugins,
      "unused-imports": unusedImports,
      inertia: inertiaLocal,
    },
    rules: {
      "import/order": [
        "error",
        {
          pathGroups: [
            {
              pattern: "@/**",
              group: "external",
              position: "after",
            },
          ],
          "newlines-between": "always",
          named: true,
          alphabetize: { order: "asc" },
        },
      ],
      "import/first": "error",
      "import/extensions": ["error", "never"],
      "@typescript-eslint/consistent-type-imports": "error",
      "@typescript-eslint/prefer-nullish-coalescing": "off",
      "@typescript-eslint/no-unused-vars": "off",
      "unused-imports/no-unused-imports": "error",
      "unused-imports/no-unused-vars": [
        "warn",
        {
          vars: "all",
          varsIgnorePattern: "^_",
          args: "after-used",
          argsIgnorePattern: "^_",
        },
      ],
      "inertia/no-manual-url-construction": "error",
      "inertia/no-field-input-import": "error",
      "inertia/no-min-h-screen-in-pages": "error",
      "inertia/no-tailwind-container": "error",
      "inertia/use-anchor-for-auth-routes": "error",
      "inertia/no-empty-select-item-value": "error",
    },
  },
  {
    files: ["**/*.js"],
    ...tseslint.configs.disableTypeChecked,
  },
];
