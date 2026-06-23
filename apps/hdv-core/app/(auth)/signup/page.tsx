'use client'

import Link from 'next/link'
import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'

export default function SignupPage() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  async function handleSignup(e: React.FormEvent) {
    e.preventDefault()
    setError('')

    if (password !== confirm) {
      setError('Passwords do not match')
      return
    }
    if (password.length < 8) {
      setError('Password must be at least 8 characters')
      return
    }

    setLoading(true)
    try {
      const supabase = createClient()
      const { error } = await supabase.auth.signUp({ email, password })

      if (error) {
        setError(error.message)
        setLoading(false)
        return
      }

      router.push('/character-creation')
      router.refresh()
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Sign-up failed')
      setLoading(false)
    }
  }

  return (
    <div className="w-full max-w-sm">
      <div className="rounded-xl border border-purple-800 bg-[#1a1a2e]/80 p-8">
        <h1 className="font-mono text-xl text-slate-200 mb-1 tracking-widest">JOIN THE CORE</h1>
        <p className="font-mono text-xs text-purple-600 mb-6">Begin your story in Periliminal.Space</p>

        <form onSubmit={handleSignup} className="space-y-4">
          <div>
            <label className="block font-mono text-xs text-purple-400 mb-1">EMAIL</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="w-full bg-[#0f0f1a] border border-purple-900 rounded-lg px-3 py-2 font-mono text-sm text-slate-200 outline-none focus:border-purple-600 transition-colors"
            />
          </div>

          <div>
            <label className="block font-mono text-xs text-purple-400 mb-1">PASSWORD</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="w-full bg-[#0f0f1a] border border-purple-900 rounded-lg px-3 py-2 font-mono text-sm text-slate-200 outline-none focus:border-purple-600 transition-colors"
            />
          </div>

          <div>
            <label className="block font-mono text-xs text-purple-400 mb-1">CONFIRM PASSWORD</label>
            <input
              type="password"
              value={confirm}
              onChange={(e) => setConfirm(e.target.value)}
              required
              className="w-full bg-[#0f0f1a] border border-purple-900 rounded-lg px-3 py-2 font-mono text-sm text-slate-200 outline-none focus:border-purple-600 transition-colors"
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
            className="w-full py-3 rounded-lg bg-purple-700 hover:bg-purple-600 disabled:opacity-50 font-mono text-sm text-white tracking-widest transition-colors border border-purple-500"
          >
            {loading ? 'CREATING...' : 'BEGIN'}
          </button>
        </form>

        <p className="mt-6 font-mono text-xs text-center text-slate-500">
          Have an account?{' '}
          <Link href="/login" className="text-purple-400 hover:text-purple-200">
            Sign in
          </Link>
        </p>
      </div>
    </div>
  )
}
