'use client'

import { FACTION_LIST } from '@/lib/game/data/factions'
import type { FactionId } from '@/types/character'

export default function StepFaction({
  value,
  onChange,
}: {
  value: FactionId | null
  onChange: (id: FactionId) => void
}) {
  return (
    <div>
      <h2 className="font-mono text-lg text-slate-200 mb-1 tracking-wider">CHOOSE YOUR FACTION</h2>
      <p className="font-mono text-xs text-slate-500 mb-6">
        Factions are permanent across all game modes. They determine your light color scheme and which
        deities serve as your companions.
      </p>

      <div className="grid grid-cols-1 gap-4">
        {FACTION_LIST.map((faction) => {
          const selected = value === faction.id

          return (
            <button
              key={faction.id}
              onClick={() => onChange(faction.id)}
              style={{
                borderColor: faction.colorScheme.glow,
                borderWidth: selected ? 2 : 1,
                borderStyle: 'solid',
                boxShadow: selected ? `0 0 20px ${faction.colorScheme.glow}40` : 'none',
              }}
              className={`text-left rounded-xl p-5 transition-all ${
                selected ? 'bg-[#1a1a2e]' : 'bg-[#1a1a2e]/40 hover:bg-[#1a1a2e]/70'
              }`}
            >
              <div className="flex items-center gap-3 mb-2">
                <div
                  className="w-3 h-3 rounded-full"
                  style={{ backgroundColor: faction.colorScheme.glow }}
                />
                <span className="font-mono text-sm tracking-widest" style={{ color: faction.colorScheme.glow }}>
                  {faction.name.toUpperCase()}
                </span>
                <span className="ml-auto font-mono text-xs text-slate-600">{faction.origin}</span>
              </div>
              <p className="font-mono text-xs text-slate-400 leading-relaxed">{faction.description}</p>
              <p className="font-mono text-xs mt-2" style={{ color: faction.colorScheme.glow }}>
                ✦ {faction.defeats_text}
              </p>
            </button>
          )
        })}
      </div>
    </div>
  )
}
