/**
 * Local ESLint rules for Inertia.js + React applications
 */

/** @type {import('eslint').ESLint.Plugin} */
const plugin = {
  meta: {
    name: "eslint-plugin-inertia-local",
    version: "1.0.0",
  },
  rules: {
    /**
     * Rule 2: No manual URL construction
     * Detects template literals or string concatenation for routes.
     * Should use js-routes helpers like itemsPath() instead.
     */
    "no-manual-url-construction": {
      meta: {
        type: "suggestion",
        docs: {
          description:
            "Disallow manual URL construction. Use js-routes helpers instead.",
        },
        messages: {
          noManualUrl:
            "Use js-routes helpers (e.g., itemsPath()) instead of manual URL construction.",
        },
        schema: [],
      },
      create(context) {
        const routePatterns = [
          /^\/[a-z]/i, // Starts with / followed by letter
          /\/\$\{/, // Template literal with interpolation in path
        ];

        return {
          TemplateLiteral(node) {
            const sourceCode = context.sourceCode || context.getSourceCode();
            const text = sourceCode.getText(node);

            // Check if it looks like a URL path
            if (routePatterns.some((pattern) => pattern.test(text))) {
              // Ignore if it's clearly not a route (e.g., file paths, regex patterns)
              if (
                text.includes("node_modules") ||
                text.includes(".js") ||
                text.includes(".ts") ||
                text.includes(".css")
              ) {
                return;
              }

              context.report({
                node,
                messageId: "noManualUrl",
              });
            }
          },

          BinaryExpression(node) {
            if (node.operator !== "+") return;

            const sourceCode = context.sourceCode || context.getSourceCode();
            const text = sourceCode.getText(node);

            // Check if concatenating strings that look like URLs
            if (
              text.includes('"/') ||
              (text.includes("Path()") && text.includes("+"))
            ) {
              context.report({
                node,
                messageId: "noManualUrl",
              });
            }
          },
        };
      },
    },

    /**
     * Rule 3: No FieldInput import
     * FieldInput doesn't exist in shadcn/ui. Use Input from @/components/ui/input instead.
     */
    "no-field-input-import": {
      meta: {
        type: "problem",
        docs: {
          description:
            "Disallow importing FieldInput which does not exist. Use Input from @/components/ui/input instead.",
        },
        messages: {
          noFieldInput:
            "FieldInput does not exist. Use Input from '@/components/ui/input' instead.",
        },
        schema: [],
      },
      create(context) {
        return {
          ImportSpecifier(node) {
            if (node.imported.name === "FieldInput") {
              context.report({
                node,
                messageId: "noFieldInput",
              });
            }
          },
        };
      },
    },

    /**
     * Rule 7: No min-h-screen in page components
     * Pages render inside PersistentLayout's <main> element.
     * Should use flex-1 instead.
     */
    "no-min-h-screen-in-pages": {
      meta: {
        type: "suggestion",
        docs: {
          description:
            "Disallow min-h-screen in page components. Use flex-1 instead.",
        },
        messages: {
          noMinHScreen:
            "Don't use 'min-h-screen' in page components. Pages are inside PersistentLayout's <main>. Use 'flex-1' instead.",
        },
        schema: [],
      },
      create(context) {
        const filename = context.filename || context.getFilename();

        // Only apply to page components
        if (!filename.includes("/pages/")) {
          return {};
        }

        return {
          JSXAttribute(node) {
            if (
              node.name.name === "className" &&
              node.value &&
              node.value.type === "Literal" &&
              typeof node.value.value === "string" &&
              node.value.value.includes("min-h-screen")
            ) {
              context.report({
                node,
                messageId: "noMinHScreen",
              });
            }

            // Handle template literals in className
            if (
              node.name.name === "className" &&
              node.value &&
              node.value.type === "JSXExpressionContainer"
            ) {
              const expr = node.value.expression;
              if (expr.type === "TemplateLiteral") {
                const sourceCode =
                  context.sourceCode || context.getSourceCode();
                const text = sourceCode.getText(expr);
                if (text.includes("min-h-screen")) {
                  context.report({
                    node,
                    messageId: "noMinHScreen",
                  });
                }
              }
            }
          },
        };
      },
    },

    /**
     * Rule 8: No Tailwind container class
     * The app is full-width and responsive, not fixed-width.
     */
    "no-tailwind-container": {
      meta: {
        type: "suggestion",
        docs: {
          description:
            "Disallow Tailwind's container class. App should be full-width.",
        },
        messages: {
          noContainer:
            "Don't use Tailwind's 'container' class. This app is full-width and responsive, not fixed-width.",
        },
        schema: [],
      },
      create(context) {
        function checkForContainer(value) {
          if (typeof value !== "string") return false;
          // Match 'container' as a standalone class
          return /(^|\s)container(\s|$)/.test(value);
        }

        return {
          JSXAttribute(node) {
            if (node.name.name !== "className") return;

            if (
              node.value &&
              node.value.type === "Literal" &&
              checkForContainer(node.value.value)
            ) {
              context.report({
                node,
                messageId: "noContainer",
              });
            }

            // Handle template literals
            if (
              node.value &&
              node.value.type === "JSXExpressionContainer" &&
              node.value.expression.type === "TemplateLiteral"
            ) {
              const sourceCode = context.sourceCode || context.getSourceCode();
              const text = sourceCode.getText(node.value.expression);
              if (checkForContainer(text)) {
                context.report({
                  node,
                  messageId: "noContainer",
                });
              }
            }
          },
        };
      },
    },

    /**
     * Rule 9: Use <a> for auth routes, not <Link>
     * Auth routes require full page redirect to work properly.
     */
    "use-anchor-for-auth-routes": {
      meta: {
        type: "problem",
        docs: {
          description:
            "Require <a> tags for auth routes instead of Inertia <Link>.",
        },
        messages: {
          useAnchor:
            "Use <a> tag instead of <Link> for auth routes ({{route}}). Auth requires full page redirect.",
        },
        schema: [],
      },
      create(context) {
        const authRoutePatterns = [
          /auth/i,
          /login/i,
          /logout/i,
          /signin/i,
          /signout/i,
          /sign_in/i,
          /sign_out/i,
          /session/i,
        ];

        function isAuthRoute(value) {
          if (typeof value !== "string") return false;
          return authRoutePatterns.some((pattern) => pattern.test(value));
        }

        function getHrefValue(node) {
          const hrefAttr = node.attributes.find(
            (attr) =>
              attr.type === "JSXAttribute" && attr.name.name === "href",
          );
          if (!hrefAttr || !hrefAttr.value) return null;

          if (hrefAttr.value.type === "Literal") {
            return hrefAttr.value.value;
          }

          if (hrefAttr.value.type === "JSXExpressionContainer") {
            const expr = hrefAttr.value.expression;
            // Handle function calls like authPath()
            if (expr.type === "CallExpression" && expr.callee.name) {
              return expr.callee.name;
            }
            // Handle identifiers
            if (expr.type === "Identifier") {
              return expr.name;
            }
          }

          return null;
        }

        return {
          JSXOpeningElement(node) {
            if (node.name.name !== "Link") return;

            const href = getHrefValue(node);
            if (href && isAuthRoute(href)) {
              context.report({
                node,
                messageId: "useAnchor",
                data: { route: href },
              });
            }
          },
        };
      },
    },

    /**
     * Rule 11: No empty SelectItem value
     * SelectItem components must have a non-empty value.
     */
    "no-empty-select-item-value": {
      meta: {
        type: "problem",
        docs: {
          description: "Require non-empty value prop on SelectItem components.",
        },
        messages: {
          noEmptyValue:
            "SelectItem must have a non-empty value prop. Empty strings are not allowed.",
        },
        schema: [],
      },
      create(context) {
        return {
          JSXOpeningElement(node) {
            if (node.name.name !== "SelectItem") return;

            const valueAttr = node.attributes.find(
              (attr) =>
                attr.type === "JSXAttribute" && attr.name.name === "value",
            );

            if (!valueAttr) {
              context.report({
                node,
                messageId: "noEmptyValue",
              });
              return;
            }

            if (
              valueAttr.value &&
              valueAttr.value.type === "Literal" &&
              valueAttr.value.value === ""
            ) {
              context.report({
                node: valueAttr,
                messageId: "noEmptyValue",
              });
            }
          },
        };
      },
    },
  },
};

export default plugin;
