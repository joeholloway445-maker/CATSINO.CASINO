'use client'

import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'

export default function SignOutButton() {
  const router = useRouter()

  async function handleSignOut() {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.push('/')
    router.refresh()
  }

  return (
    <button
      onClick={handleSignOut}
      className="px-3 py-1.5 rounded-lg border border-neon-pink/40 text-neon-pink text-xs tracking-wide hover:bg-neon-pink/10 transition-colors"
    >
      SIGN OUT
    </button>
  )
}
