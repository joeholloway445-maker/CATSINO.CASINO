'use client'

import Link from 'next/link'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'

export default function SignupPage() {
  const router = useRouter()
  const [username, setUsername] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [done, setDone] = useState(false)

  async function handleSignup(e: React.FormEvent) {
    e.preventDefault()
    setError('')
    setLoading(true)

    const supabase = createClient()
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { username } },
    })

    if (error) {
      setError(error.message)
      setLoading(false)
      return
    }

    if (data.session) {
      router.push('/dashboard')
      router.refresh()
      return
    }

    setDone(true)
    setLoading(false)
  }

  if (done) {
    return (
      <div className="w-full max-w-sm">
        <div className="rounded-xl border border-neon-green/40 bg-[#0a0813]/80 p-8 text-center">
          <div className="text-4xl mb-3">🐈‍⬛✉️</div>
          <h1 className="font-display text-lg text-neon-green neon-text mb-2 tracking-widest">CHECK YOUR EMAIL</h1>
          <p className="font-mono text-xs text-slate-400">
            Confirm your email to claim your 10,000 starting Cat Chips and enter the casino.
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="w-full max-w-sm">
      <div className="rounded-xl border border-neon-purple/40 bg-[#0a0813]/80 p-8 neon-border">
        <h1 className="font-display text-xl text-neon-purple neon-text mb-1 tracking-widest">JOIN THE PRIDE</h1>
        <p className="font-mono text-xs text-slate-400 mb-6">Start with 10,000 free Cat Chips</p>

        <form onSubmit={handleSignup} className="space-y-4">
          <div>
            <label className="block font-mono text-xs text-neon-cyan mb-1">USERNAME</label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required
              minLength={3}
              maxLength={20}
              pattern="[a-zA-Z0-9_]+"
              className="w-full bg-black/40 border border-neon-purple/30 rounded-lg px-3 py-2 font-mono text-sm text-slate-200 outline-none focus:border-neon-cyan transition-colors"
            />
          </div>

          <div>
            <label className="block font-mono text-xs text-neon-cyan mb-1">EMAIL</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="w-full bg-black/40 border border-neon-purple/30 rounded-lg px-3 py-2 font-mono text-sm text-slate-200 outline-none focus:border-neon-cyan transition-colors"
            />
          </div>

          <div>
            <label className="block font-mono text-xs text-neon-cyan mb-1">PASSWORD</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              minLength={6}
              className="w-full bg-black/40 border border-neon-purple/30 rounded-lg px-3 py-2 font-mono text-sm text-slate-200 outline-none focus:border-neon-cyan transition-colors"
            />
          </div>

          {error && (
            <div className="font-mono text-xs text-red-400 bg-red-950/50 border border-red-900 rounded px-3 py-2">
              {error}
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 rounded-lg bg-neon-purple hover:opacity-90 disabled:opacity-50 font-display text-sm text-white tracking-widest transition-opacity"
          >
            {loading ? 'CREATING...' : 'CREATE ACCOUNT'}
          </button>
        </form>

        <p className="mt-6 font-mono text-xs text-center text-slate-500">
          Already have an account?{' '}
          <Link href="/login" className="text-neon-cyan hover:text-neon-purple">
            Sign in
          </Link>
        </p>
      </div>
    </div>
  )
}
