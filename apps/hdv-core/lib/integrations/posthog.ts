import posthog from 'posthog-js'

export function initPostHog() {
  if (typeof window === 'undefined') return
  const key = process.env.NEXT_PUBLIC_POSTHOG_KEY
  const host = process.env.NEXT_PUBLIC_POSTHOG_HOST ?? 'https://us.i.posthog.com'
  if (!key) return
  posthog.init(key, {
    api_host: host,
    person_profiles: 'identified_only',
    capture_pageview: false,
  })
}

export function trackEvent(event: string, props?: Record<string, unknown>) {
  if (typeof window === 'undefined') return
  posthog.capture(event, props)
}

export function identifyUser(userId: string, traits?: Record<string, unknown>) {
  if (typeof window === 'undefined') return
  posthog.identify(userId, traits)
}

export { posthog }
