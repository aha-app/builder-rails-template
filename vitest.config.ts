import tailwindcss from "@tailwindcss/vite"
import react from "@vitejs/plugin-react"
import { defineConfig } from "vitest/config"

export default defineConfig({
  plugins: [
    react({
      babel: {
        plugins: ["babel-plugin-react-compiler"],
      },
    }),
    tailwindcss(),
  ],
  test: {
    globals: true,
    environment: "jsdom",
    setupFiles: ["./app/frontend/test/setup.ts"],
    include: ["app/frontend/**/*.{test,spec}.{ts,tsx}"],
    alias: {
      "@": new URL("./app/frontend", import.meta.url).pathname,
    },
  },
})
