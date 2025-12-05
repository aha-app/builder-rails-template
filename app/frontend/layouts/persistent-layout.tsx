import type { ReactNode } from "react"
import { Fragment } from "react"

import { Toaster } from "@/components/ui/sonner"

interface PersistentLayoutProps {
  children: ReactNode
}

export default function PersistentLayout({ children }: PersistentLayoutProps) {
  return (
    <Fragment>
      {children}
      <Toaster richColors />
    </Fragment>
  )
}
