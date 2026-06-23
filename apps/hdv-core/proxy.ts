import { createServerClient } from '@supabase/ssr'
import { type NextRequest, NextResponse } from 'next/server'

// Browser pages that never require a signed-in user. /studio and /builder run
// entirely client-side + the in-memory backbone, so they work as public demos
// with no Supabase needed.
const PUBLIC_ROUTES = ['/', '/login', '/signup', '/studio', '/builder']

export async function proxy(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })
  const { pathname } = request.nextUrl

  // API routes own their own auth (public reads, X-Api-Key tenant billing, or
  // none at all) — the session check below is for browser pages only.
  if (pathname.startsWith('/api/')) return supabaseResponse

  // Auth pages don't need protection
  if (pathname.startsWith('/(auth)') || pathname === '/login' || pathname === '/signup') {
    return supabaseResponse
  }

  const isPublic = PUBLIC_ROUTES.includes(pathname)

  // If Supabase isn't configured (or the auth call fails), never 500 the whole
  // site — degrade to "no session" and let public routes through. Protected
  // routes still bounce to /login, where the app surfaces the real config state.
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL
  const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
  if (!url || !anonKey) {
    if (isPublic) return supabaseResponse
    const loginUrl = request.nextUrl.clone()
    loginUrl.pathname = '/login'
    return NextResponse.redirect(loginUrl)
  }

  const supabase = createServerClient(url, anonKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll()
      },
      setAll(cookiesToSet) {
        cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
        supabaseResponse = NextResponse.next({ request })
        cookiesToSet.forEach(({ name, value, options }) =>
          supabaseResponse.cookies.set(name, value, options),
        )
      },
    },
  })

  let user = null
  try {
    user = (await supabase.auth.getUser()).data.user
  } catch {
    // Auth backend unreachable — treat as unauthenticated rather than crashing.
  }

  // Redirect unauthenticated users away from protected routes
  if (!user && !isPublic) {
    const loginUrl = request.nextUrl.clone()
    loginUrl.pathname = '/login'
    return NextResponse.redirect(loginUrl)
  }

  return supabaseResponse
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)'],
}
