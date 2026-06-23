'use client'

import dynamic from 'next/dynamic'

// BuilderShell uses browser-only APIs (IndexedDB via idb, window, Monaco's
// worker bootstrapping) so it must never run during SSR/static generation.
// next/dynamic's `ssr: false` option can only be used from a Client
// Component in this Next.js version, so this thin wrapper exists purely to
// host that call — app/builder/page.tsx stays a server component.
const BuilderShell = dynamic(() => import('@/components/builder/BuilderShell'), {
  ssr: false,
})

export default function BuilderShellLoader() {
  return <BuilderShell />
}
