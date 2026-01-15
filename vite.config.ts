import tailwindcss from "@tailwindcss/vite"
import react from "@vitejs/plugin-react"
import { defineConfig } from "vite"
import EnvironmentPlugin from "vite-plugin-environment"
import ViteRuby from "vite-plugin-ruby"

import { ahaBuilderIdsPlugin } from "./vite-plugin-aha-builder-ids"

export default defineConfig({
  plugins: [
    ahaBuilderIdsPlugin(),
    react({
      babel: {
        plugins: ["babel-plugin-react-compiler"],
      },
    }),
    tailwindcss(),
    ViteRuby(),
    EnvironmentPlugin({ RAILS_ENV: "development" }),
  ],
  server: {
    hmr: {
      clientPort: parseInt(process.env.HMR_PROXY_PORT || "443"),
    },
  },
  logLevel: "error",
  build: {
    reportCompressedSize: false,
    rollupOptions: {
      onwarn(warning, warn) {
        // Suppress specific warnings
        if (warning.code === "EVAL") return
        warn(warning)
      },
    },
  },
})
