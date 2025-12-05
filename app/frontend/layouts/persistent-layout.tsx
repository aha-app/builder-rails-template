import type { ReactNode } from "react"

import { Toaster } from "@/components/ui/sonner"

interface PersistentLayoutProps {
  children: ReactNode
}

export default function PersistentLayout({ children }: PersistentLayoutProps) {
  return (
    <div className="flex min-h-screen flex-col">
      {children}
      <Toaster richColors />
    </div>
  )
}
