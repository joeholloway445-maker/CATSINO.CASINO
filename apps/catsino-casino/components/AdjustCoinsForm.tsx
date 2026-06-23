'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

export default function AdjustCoinsForm({ userId }: { userId: string }) {
  const router = useRouter()
  const [amount, setAmount] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function adjust(e: React.FormEvent) {
    e.preventDefault()
    const parsed = Number(amount)
    if (!Number.isFinite(parsed) || parsed === 0) return

    setLoading(true)
    setError('')

    const res = await fetch('/api/admin/adjust-coins', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userId, amount: parsed }),
    })

    const data = await res.json()

    if (!res.ok) {
      setError(data.error ?? 'Failed')
      setLoading(false)
      return
    }

    setAmount('')
    setLoading(false)
    router.refresh()
  }

  return (
    <form onSubmit={adjust} className="flex items-center gap-2">
      <input
        type="number"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
        placeholder="+/- coins"
        className="w-28 bg-black/40 border border-neon-purple/30 rounded px-2 py-1 text-xs font-mono text-slate-200 outline-none focus:border-neon-cyan"
      />
      <button
        type="submit"
        disabled={loading}
        className="px-3 py-1 rounded text-xs font-mono border border-neon-green/40 text-neon-green hover:bg-neon-green/10 disabled:opacity-40"
      >
        APPLY
      </button>
      {error && <span className="text-xs text-red-400">{error}</span>}
    </form>
  )
}
