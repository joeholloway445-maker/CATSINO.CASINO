'use client'

import { useRouter } from 'next/navigation'
import { useState } from 'react'
import { usePortraitUrl } from '@/lib/character/mediaStore'

interface CharacterSummary {
  id: string
  slotNumber: number
  faction: string
  raceName: string
  frameName: string
  prestigeLevel: number
}

interface Props {
  slots: number
  characters: CharacterSummary[]
  coin: number
}

const SLOT_COST_COIN = 500

export default function CharacterSelectClient({ slots, characters, coin }: Props) {
  const router = useRouter()
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')

  const bySlot = new Map(characters.map((c) => [c.slotNumber, c]))
  const slotNumbers = Array.from({ length: slots }, (_, i) => i + 1)

  async function selectCharacter(characterId: string) {
    setBusy(true)
    setError('')
    const res = await fetch('/api/character/select', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ characterId }),
    })
    if (!res.ok) {
      setError('Could not select character.')
      setBusy(false)
      return
    }
    router.push('/game/extraliminal')
  }

  function createInSlot(slotNumber: number) {
    router.push(`/character-creation?slot=${slotNumber}`)
  }

  async function buySlot() {
    setBusy(true)
    setError('')
    const res = await fetch('/api/character/buy-slot', { method: 'POST' })
    if (!res.ok) {
      const body = await res.json().catch(() => ({}))
      setError(body.error === 'not enough coin' ? 'Not enough coin for a new slot.' : 'Could not buy slot.')
      setBusy(false)
      return
    }
    router.refresh()
    setBusy(false)
  }

  return (
    <div className="min-h-screen bg-[#0f0f1a] px-4 py-8">
      <div className="max-w-3xl mx-auto">
        <div className="flex items-center justify-between mb-2">
          <h1 className="font-mono text-xl text-slate-200 tracking-widest">SELECT YOUR BUILD</h1>
          <div className="flex items-center gap-4">
            <a href="/campaign" className="font-mono text-xs text-purple-500 hover:text-purple-300">
              CAMPAIGN →
            </a>
            <a href="/story" className="font-mono text-xs text-purple-500 hover:text-purple-300">
              PLOTS →
            </a>
            <a href="/omnidex" className="font-mono text-xs text-purple-500 hover:text-purple-300">
              OMNIDEX →
            </a>
            <a href="/endgame" className="font-mono text-xs text-purple-500 hover:text-purple-300">
              ROADMAP →
            </a>
          </div>
        </div>
        <p className="font-mono text-xs text-purple-600 mb-6">Choose an existing build or create a new one to continue.</p>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
          {slotNumbers.map((slotNumber) => {
            const character = bySlot.get(slotNumber)
            return (
              <div
                key={slotNumber}
                className="rounded-xl border border-purple-900 bg-[#1a1a2e]/50 p-4 h-44 flex flex-col"
              >
                {character ? (
                  <>
                    <div className="flex items-center gap-2 mb-1">
                      <div className="font-mono text-xs text-purple-600">SLOT {slotNumber}</div>
                      <SlotPortrait slot={slotNumber} />
                    </div>
                    <div className="font-mono text-sm text-slate-200">{character.raceName}</div>
                    <div className="font-mono text-xs text-slate-500">{character.frameName}</div>
                    <div className="font-mono text-xs text-slate-500 mb-3">Prestige {character.prestigeLevel}</div>
                    <div className="flex-1" />
                    <button
                      disabled={busy}
                      onClick={() => selectCharacter(character.id)}
                      className="px-4 py-2 rounded-lg bg-purple-700 hover:bg-purple-600 disabled:opacity-50 font-mono text-xs text-white tracking-widest border border-purple-500"
                    >
                      ENTER
                    </button>
                  </>
                ) : (
                  <>
                    <div className="font-mono text-xs text-slate-600 mb-1">SLOT {slotNumber}</div>
                    <div className="flex-1 flex items-center justify-center font-mono text-xs text-slate-700">EMPTY</div>
                    <button
                      disabled={busy}
                      onClick={() => createInSlot(slotNumber)}
                      className="px-4 py-2 rounded-lg border border-slate-700 hover:border-slate-500 disabled:opacity-50 font-mono text-xs text-slate-300 tracking-widest"
                    >
                      + NEW BUILD
                    </button>
                  </>
                )}
              </div>
            )
          })}
        </div>

        <button
          disabled={busy || coin < SLOT_COST_COIN}
          onClick={buySlot}
          className="px-4 py-2 rounded-lg border border-slate-700 hover:border-slate-500 disabled:opacity-30 font-mono text-xs text-slate-400 tracking-widest"
        >
          BUY EXTRA SLOT — {SLOT_COST_COIN} COIN
        </button>

        {error && (
          <div className="mt-4 font-mono text-xs text-red-400 bg-red-950/50 border border-red-900 rounded px-3 py-2">
            {error}
          </div>
        )}
      </div>
    </div>
  )
}

/** Avatar captured in the CAPTURE step of character creation, if any (stored locally per slot). */
function SlotPortrait({ slot }: { slot: number }) {
  const url = usePortraitUrl(slot)
  if (!url) return null
  // eslint-disable-next-line @next/next/no-img-element
  return <img src={url} alt="" className="w-5 h-5 rounded-full object-cover border border-purple-700" />
}
