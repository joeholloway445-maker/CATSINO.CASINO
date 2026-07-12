'use client'

import { useState } from 'react'
import { FRAMES } from '@/lib/game/data/frames'

const STAT_LABEL: Record<string, string> = {
  agility: 'AGI',
  power: 'PWR',
  resonance: 'RES',
  frequency: 'FRQ',
}

function StatBar({ value, max = 10 }: { value: number; max?: number }) {
  const pct = Math.min((value / max) * 100, 100)
  return (
    <div className="h-1 bg-slate-800 rounded overflow-hidden">
      <div
        className="h-full bg-purple-500 rounded transition-all"
        style={{ width: `${pct}%` }}
      />
    </div>
  )
}

export default function StepFrame({ value, onChange }: { value: string | null; onChange: (id: string) => void }) {
  const [filter, setFilter] = useState('')
  const filtered = FRAMES.filter(
    (f) =>
      filter === '' ||
      f.name.toLowerCase().includes(filter.toLowerCase()) ||
      f.role.toLowerCase().includes(filter.toLowerCase()),
  )

  return (
    <div>
      <h2 className="font-mono text-lg text-slate-200 mb-1 tracking-wider">CHOOSE YOUR FRAME</h2>
      <p className="font-mono text-xs text-slate-500 mb-4">
        Frame determines your light, sound, mobility, and combat math. Exactly 20 OmniDex frames.
      </p>

      <input
        type="text"
        value={filter}
        onChange={(e) => setFilter(e.target.value)}
        placeholder="Filter frames..."
        className="w-full mb-4 bg-[#0f0f1a] border border-purple-900 rounded-lg px-3 py-2 font-mono text-xs text-slate-300 outline-none focus:border-purple-600 transition-colors"
      />

      <div className="grid grid-cols-2 gap-2 max-h-[420px] overflow-y-auto pr-1">
        {filtered.map((frame) => {
          const selected = value === frame.id
          return (
            <button
              key={frame.id}
              onClick={() => onChange(frame.id)}
              className={`text-left rounded-lg border p-3 transition-all ${
                selected
                  ? 'border-purple-500 bg-purple-950/60'
                  : 'border-slate-800 bg-[#1a1a2e]/40 hover:border-slate-600'
              }`}
            >
              <div className="flex items-center justify-between mb-0.5">
                <span className="font-mono text-xs text-slate-200">{frame.name}</span>
                <span className="font-mono text-xs text-slate-600 uppercase">{frame.frameType}</span>
              </div>
              <div className="font-mono text-xs text-purple-600 mb-1">{frame.role}</div>
              <div className="font-mono text-xs text-cyan-400 mb-2">
                {frame.exclusiveStat.name} — {frame.exclusiveStat.effect}
              </div>
              <div className="space-y-1">
                {Object.entries(frame.stats).map(([stat, val]) => (
                  <div key={stat} className="flex items-center gap-2">
                    <span className="font-mono text-xs text-slate-600 w-8">{STAT_LABEL[stat]}</span>
                    <div className="flex-1">
                      <StatBar value={val} />
                    </div>
                    <span className="font-mono text-xs text-slate-400 w-3 text-right">{val}</span>
                  </div>
                ))}
              </div>
            </button>
          )
        })}
      </div>
    </div>
  )
}
