'use client'

import { useState } from 'react'
import { RACES } from '@/lib/game/data/races'

export default function StepRace({ value, onChange }: { value: string | null; onChange: (id: string) => void }) {
  const [filter, setFilter] = useState('')
  const filtered = RACES.filter(
    (r) =>
      filter === '' ||
      r.name.toLowerCase().includes(filter.toLowerCase()) ||
      r.texture.type.toLowerCase().includes(filter.toLowerCase()),
  )

  return (
    <div>
      <h2 className="font-mono text-lg text-slate-200 mb-1 tracking-wider">CHOOSE YOUR RACE</h2>
      <p className="font-mono text-xs text-slate-500 mb-4">
        Race determines your texture — how this reality renders your physical form. 20 races available.
      </p>

      <input
        type="text"
        value={filter}
        onChange={(e) => setFilter(e.target.value)}
        placeholder="Filter races..."
        className="w-full mb-4 bg-[#0f0f1a] border border-purple-900 rounded-lg px-3 py-2 font-mono text-xs text-slate-300 outline-none focus:border-purple-600 transition-colors"
      />

      <div className="grid grid-cols-2 gap-2 max-h-[420px] overflow-y-auto pr-1">
        {filtered.map((race) => {
          const selected = value === race.id
          return (
            <button
              key={race.id}
              onClick={() => onChange(race.id)}
              className={`text-left rounded-lg border p-3 transition-all ${
                selected
                  ? 'border-purple-500 bg-purple-950/60'
                  : 'border-slate-800 bg-[#1a1a2e]/40 hover:border-slate-600'
              }`}
            >
              <div className="flex items-center gap-2 mb-1">
                <div
                  className="w-2.5 h-2.5 rounded-full flex-shrink-0"
                  style={{ backgroundColor: race.texture.primaryColor }}
                />
                <span className="font-mono text-xs text-slate-200 truncate">{race.name}</span>
              </div>
              <div className="font-mono text-xs text-purple-600 mb-1">{race.texture.type}</div>
              <div className="font-mono text-xs text-slate-500 leading-tight line-clamp-2">
                {race.description}
              </div>
              {Object.keys(race.statBonus).length > 0 && (
                <div className="mt-1.5 flex flex-wrap gap-1">
                  {Object.entries(race.statBonus).map(([stat, val]) => (
                    <span
                      key={stat}
                      className={`font-mono text-xs px-1 rounded ${
                        (val ?? 0) > 0 ? 'text-green-400 bg-green-950' : 'text-red-400 bg-red-950'
                      }`}
                    >
                      {stat} {(val ?? 0) > 0 ? '+' : ''}{val}
                    </span>
                  ))}
                </div>
              )}
              <div className="mt-1.5 font-mono text-xs text-cyan-400">
                {race.passive.name} — {race.passive.effect}
              </div>
              <div className="font-mono text-xs text-red-500/80">{race.drawback}</div>
            </button>
          )
        })}
      </div>
    </div>
  )
}
