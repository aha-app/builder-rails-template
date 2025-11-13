import { createInertiaApp } from "@inertiajs/react";
import {
  type ComponentType,
  type ReactNode,
  StrictMode,
  createElement,
} from "react";
import { createRoot } from "react-dom/client";

import { initializeTheme } from "@/hooks/use-appearance";
import PersistentLayout from "@/layouts/persistent-layout";

// Temporary type definition, until @inertiajs/react provides one
type PageComponent = ComponentType<Record<string, unknown>> & {
  layout?: (page: ReactNode) => ReactNode;
};

interface ResolvedComponent {
  default: PageComponent;
}

const appName = import.meta.env.VITE_APP_NAME ?? "Builder";

createInertiaApp({
  title: (title) => (title ? `${title} - ${appName}` : appName),

  resolve: (name) => {
    const pages = import.meta.glob<ResolvedComponent>("../pages/**/*.tsx", {
      eager: true,
    });
    const page = pages[`../pages/${name}.tsx`];
    if (!page) {
      throw new Error(`Missing Inertia page component: '${name}.tsx'`);
    }

    page.default.layout ??= (pageContent: ReactNode) =>
      createElement(PersistentLayout, null, pageContent);

    return page;
  },

  setup({ el, App, props }) {
    createRoot(el).render(
      <StrictMode>
        <App {...props} />
      </StrictMode>,
    );
  },

  defaults: {
    future: {
      useDataInertiaHeadAttribute: true,
      useDialogForErrorModal: true,
      preserveEqualProps: true,
    },
    visitOptions: () => {
      return { queryStringArrayFormat: "brackets" };
    },
  },
}).catch((error) => {
  // This ensures this entrypoint is only loaded on Inertia pages
  // by checking for the presence of the root element (#app by default).
  // Feel free to remove this `catch` if you don't need it.
  if (document.getElementById("app")) {
    throw error;
  } else {
    console.error(
      "Missing root element.\n\n" +
        "If you see this error, it probably means you loaded Inertia.js on non-Inertia pages.\n" +
        'Consider moving <%= vite_typescript_tag "inertia" %> to the Inertia-specific layout instead.',
    );
  }
});

// This will set light / dark mode on load...
initializeTheme();
