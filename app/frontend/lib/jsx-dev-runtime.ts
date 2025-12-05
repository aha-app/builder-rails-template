/* eslint-disable @typescript-eslint/no-explicit-any */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-argument */
import { jsx as _jsx } from "react/jsx-runtime"

interface Source {
  fileName: string
  lineNumber: number
}

export function jsxDEV(
  type: any,
  props: any,
  key: any,
  _isStaticChildren: any,
  source: Source | undefined,
) {
  let typeName: string

  if (typeof type === "function") {
    typeName = type.name ?? "Anonymous"
  } else if (
    typeof type === "object" &&
    type !== null &&
    "displayName" in type
  ) {
    typeName = type.displayName
  } else {
    typeName = String(type)
  }

  // Add metadata attributes to props
  const enhancedProps = {
    ...props,
    "data-component": typeName,
    "data-source": source
      ? `${source.fileName}:${source.lineNumber}`
      : undefined,
  }

  return _jsx(type, enhancedProps, key)
}

// Re-export everything else from the original runtime
export * from "react/jsx-runtime"
