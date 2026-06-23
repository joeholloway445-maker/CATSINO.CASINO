'use client'
import { useEffect } from 'react'
import { usePathname } from 'next/navigation'
import { initPostHog, trackEvent, posthog } from '@/lib/integrations/posthog'

export default function PostHogProvider({ children }: { children: React.ReactNode }) {
  const pathname = usePathname()

  useEffect(() => {
    initPostHog()
  }, [])

  useEffect(() => {
    if (posthog.__loaded) {
      trackEvent('$pageview', { $current_url: window.location.href })
    }
  }, [pathname])

  return <>{children}</>
}
