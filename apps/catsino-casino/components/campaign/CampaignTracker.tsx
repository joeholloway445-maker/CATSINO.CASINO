'use client'

import { useEffect, useState } from 'react'

interface Kill {
  id: string
  killer_id: string
  victim_id: string
  killer_faction: string
  victim_faction: string
  zone_id: string | null
  dropped_tokens: number
  claimed_by: string | null
  claimed_at: string | null
  occurred_at: string
}

interface Campaign {
  id: string
  label: string
  status: string
  started_at: string
}

function elapsed(startedAt: string) {
  const ms = Date.now() - new Date(startedAt).getTime()
  const days = Math.floor(ms / 86400000)
  const hours = Math.floor((ms % 86400000) / 3600000)
  const minutes = Math.floor((ms % 3600000) / 60000)
  return `${days}d ${hours}h ${minutes}m`
}

export default function CampaignTracker() {
  const [campaign, setCampaign] = useState<Campaign | null>(null)
  const [factionScores, setFactionScores] = useState<Record<string, number>>({})
  const [recentKills, setRecentKills] = useState<Kill[]>([])
  const [lootable, setLootable] = useState<Kill[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [pending, setPending] = useState<string | null>(null)
  const [now, setNow] = useState(Date.now())

  const load = async () => {
    const res = await fetch('/api/campaign/status')
    const data = await res.json()
    if (data.campaign) setCampaign(data.campaign)
    if (data.factionScores) setFactionScores(data.factionScores)
    if (data.recentKills) setRecentKills(data.recentKills)
    if (data.lootable) setLootable(data.lootable)
    setLoading(false)
  }

  useEffect(() => {
    load()
    const poll = setInterval(load, 15000)
    const clock = setInterval(() => setNow(Date.now()), 1000)
    return () => {
      clearInterval(poll)
      clearInterval(clock)
    }
  }, [])

  const claim = async (killId: string) => {
    setPending(killId)
    setError('')
    try {
      const res = await fetch('/api/campaign/claim-loot', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ killId }),
      })
      const data = await res.json()
      if (data.error) {
        setError(data.error)
        return
      }
      await load()
    } catch {
      setError('Network error')
    } finally {
      setPending(null)
    }
  }

  if (loading) {
    return <p className="font-mono text-sm text-gray-500">Loading campaign…</p>
  }

  if (!campaign) {
    return <p className="font-mono text-sm text-gray-500">No active campaign right now.</p>
  }

  const scoreRows = Object.entries(factionScores).sort((a, b) => b[1] - a[1])

  return (
    <div className="space-y-6">
      {error && <p className="font-mono text-xs text-red-400">{error}</p>}

      <div className="border border-purple-900/60 rounded-xl bg-black/30 p-5">
        <div className="flex items-center justify-between mb-1">
          <h2 className="text-lg font-bold text-purple-300">{campaign.label}</h2>
          <span className="text-xs font-mono px-2 py-0.5 rounded bg-green-900/50 text-green-300">
            RUNNING {elapsed(campaign.started_at)}
          </span>
        </div>
        <div className="mt-4 space-y-1">
          {scoreRows.length === 0 && <p className="text-xs text-gray-500">No kills logged yet.</p>}
          {scoreRows.map(([faction, score]) => (
            <div key={faction} className="flex items-center justify-between text-sm">
              <span className="text-gray-300">{faction}</span>
              <span className="text-purple-400 font-mono">{score}</span>
            </div>
          ))}
        </div>
      </div>

      <div className="border border-yellow-900/60 rounded-xl bg-black/30 p-5">
        <h3 className="text-sm font-bold text-yellow-300 mb-3">LOOTABLE BODIES</h3>
        {lootable.length === 0 && <p className="text-xs text-gray-500">Nothing to loot right now.</p>}
        <div className="space-y-2">
          {lootable.map((k) => {
            const recoverableUntil = new Date(k.occurred_at).getTime() + 2 * 60 * 1000
            const stillGrace = now < recoverableUntil
            return (
              <div key={k.id} className="flex items-center justify-between text-xs bg-gray-900/40 rounded px-3 py-2">
                <span className="text-gray-400">
                  {k.victim_faction} body · {k.dropped_tokens} tokens
                  {stillGrace && <span className="text-cyan-400"> (victim grace period)</span>}
                </span>
                <button
                  disabled={pending === k.id}
                  onClick={() => claim(k.id)}
                  className="bg-yellow-700 hover:bg-yellow-600 disabled:opacity-50 text-white px-2 py-1 rounded"
                >
                  Loot
                </button>
              </div>
            )
          })}
        </div>
      </div>

      <div className="border border-gray-800 rounded-xl bg-black/30 p-5">
        <h3 className="text-sm font-bold text-gray-300 mb-3">RECENT KILLS</h3>
        {recentKills.length === 0 && <p className="text-xs text-gray-500">No activity yet.</p>}
        <div className="space-y-1 max-h-64 overflow-y-auto">
          {recentKills.map((k) => (
            <p key={k.id} className="text-xs text-gray-500">
              {k.killer_faction} killed {k.victim_faction}
              {k.zone_id ? ` in ${k.zone_id}` : ''} — {k.dropped_tokens} tokens dropped
            </p>
          ))}
        </div>
      </div>
    </div>
  )
}
