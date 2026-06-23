'use client'

import { useRouter } from 'next/navigation'
import { useState } from 'react'

export default function DailyBonusButton({ canClaim }: { canClaim: boolean }) {
  const router = useRouter()
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')

  async function claim() {
    setLoading(true)
    setMessage('')

    const res = await fetch('/api/daily-bonus', { method: 'POST' })
    const data = await res.json()

    if (!res.ok) {
      setMessage(data.error ?? 'Could not claim bonus')
      setLoading(false)
      return
    }

    setMessage(`+${data.reward.toLocaleString()} Cat Chips! Streak: ${data.streak}`)
    setLoading(false)
    router.refresh()
  }

  return (
    <div className="rounded-xl border border-neon-green/40 bg-[#0a0813]/80 p-5 flex flex-col gap-2">
      <h3 className="font-display text-sm tracking-wide text-neon-green">DAILY BONUS</h3>
      <p className="text-xs text-slate-400">Claim free Cat Chips every day. Keep your streak alive!</p>
      <button
        onClick={claim}
        disabled={!canClaim || loading}
        className="mt-2 px-4 py-2 rounded-lg bg-neon-green/90 text-black font-display text-xs tracking-widest disabled:opacity-40 hover:opacity-90 transition-opacity"
      >
        {loading ? 'CLAIMING...' : canClaim ? 'CLAIM BONUS' : 'ALREADY CLAIMED'}
      </button>
      {message && <p className="text-xs text-neon-green">{message}</p>}
    </div>
  )
}
