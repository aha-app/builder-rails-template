import path from "path"

import _generate from "@babel/generator"
import { parse } from "@babel/parser"
import type { NodePath } from "@babel/traverse"
import _traverse from "@babel/traverse"
import * as t from "@babel/types"
import type { Plugin } from "vite"

export const AHA_BUILDER_IDS_PLUGIN_VERSION = "2025-01-07-v1"

type TraverseModule = typeof _traverse & { default?: typeof _traverse }
type GenerateModule = typeof _generate & { default?: typeof _generate }

const traverse = (_traverse as TraverseModule).default || _traverse
const generate = (_generate as GenerateModule).default || _generate

const DEBUG_AHA_BUILDER_IDS = process.env.DEBUG_AHA_BUILDER_IDS === "true"

export function ahaBuilderIdsPlugin(): Plugin {
  let root = ""

  return {
    name: "vite-plugin-aha-builder-ids",
    enforce: "pre",

    configResolved(config) {
      root = config.root
      if (DEBUG_AHA_BUILDER_IDS) {
        console.log("[aha-builder-ids] Plugin initialized with root:", root)
      }
    },

    transform(code, id) {
      if (process.env.NODE_ENV !== "development") {
        return null
      }

      if (id.includes("node_modules")) {
        return null
      }

      const cleanId = id.split("?")[0]
      if (!/\.[jt]sx$/.test(cleanId)) {
        return null
      }

      const isRouteFile = id.includes("/routes/") || id.includes("\\routes\\")
      if (DEBUG_AHA_BUILDER_IDS || isRouteFile) {
        console.log("[aha-builder-ids] Processing file:", id)
      }

      try {
        const ast = parse(code, {
          sourceType: "module",
          plugins: ["jsx", "typescript"],
        })

        let hasChanges = false
        let addedCount = 0

        let sourceFile: string
        const appFrontendIndex = cleanId.indexOf("/app/frontend/")
        if (appFrontendIndex !== -1) {
          sourceFile = cleanId.slice(appFrontendIndex + 1).replace(/\.[jt]sx$/, "")
        } else if (cleanId.startsWith(root)) {
          sourceFile = "app/frontend/" + path.relative(root, cleanId).replace(/\.[jt]sx$/, "")
        } else {
          sourceFile = "app/frontend/" + path.basename(cleanId).replace(/\.[jt]sx$/, "")
        }

        traverse(ast, {
          JSXElement(nodePath: NodePath<t.JSXElement>) {
            const { openingElement } = nodePath.node
            const elementName = openingElement.name

            if (!t.isJSXIdentifier(elementName)) return

            const isCustomComponent = /^[A-Z]/.test(elementName.name)

            const skipElements = [
              "Fragment",
              "Suspense",
              "StrictMode",
              "Profiler",
            ]
            if (isCustomComponent && skipElements.includes(elementName.name))
              return

            const hasId = openingElement.attributes.some(
              (attr: t.JSXAttribute | t.JSXSpreadAttribute) =>
                t.isJSXAttribute(attr) &&
                t.isJSXIdentifier(attr.name) &&
                attr.name.name === "data-aha-builder-id",
            )

            if (hasId) return

            const hasSpread = openingElement.attributes.some(
              (attr: t.JSXAttribute | t.JSXSpreadAttribute) =>
                t.isJSXSpreadAttribute(attr),
            )

            if (hasSpread) return

            const loc = openingElement.loc
            if (!loc) return

            const builderId = `${sourceFile}:${loc.start.line}`

            openingElement.attributes.push(
              t.jsxAttribute(
                t.jsxIdentifier("data-aha-builder-id"),
                t.stringLiteral(builderId),
              ),
            )

            hasChanges = true
            addedCount++
          },
        })

        if (!hasChanges) {
          if (DEBUG_AHA_BUILDER_IDS && isRouteFile) {
            console.log("[aha-builder-ids] No changes needed for:", id)
          }
          return null
        }

        if (DEBUG_AHA_BUILDER_IDS || isRouteFile) {
          console.log(
            "[aha-builder-ids] Added " + addedCount + " builder IDs to:",
            sourceFile,
          )
        }

        const output = generate(ast, {}, code)
        return {
          code: output.code,
          map: output.map,
        }
      } catch (error) {
        console.error("[aha-builder-ids] Error transforming file:", id, error)
        return null
      }
    },
  }
}
