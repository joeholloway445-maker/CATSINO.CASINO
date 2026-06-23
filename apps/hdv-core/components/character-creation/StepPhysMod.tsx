'use client'

import { PHYSICAL_MODS } from '@/lib/game/data/physicalMods'

export default function StepPhysMod({ value, onChange }: { value: string | null; onChange: (id: string) => void }) {
  return (
    <div>
      <h2 className="font-mono text-lg text-slate-200 mb-1 tracking-wider">CHOOSE YOUR PHYSICAL MOD</h2>
      <p className="font-mono text-xs text-slate-500 mb-4">
        Physical mods are visual augmentations that add minor stat bonuses. 20 options available.
      </p>

      <div className="grid grid-cols-2 gap-2 max-h-[460px] overflow-y-auto pr-1">
        {PHYSICAL_MODS.map((mod) => {
          const selected = value === mod.id
          return (
            <button
              key={mod.id}
              onClick={() => onChange(mod.id)}
              className={`text-left rounded-lg border p-3 transition-all ${
                selected
                  ? 'border-purple-500 bg-purple-950/60'
                  : 'border-slate-800 bg-[#1a1a2e]/40 hover:border-slate-600'
              }`}
            >
              <div className="font-mono text-xs text-slate-200 mb-1">{mod.name}</div>
              <div className="font-mono text-xs text-slate-500 leading-tight line-clamp-2 mb-1.5">
                {mod.description}
              </div>
              <div className="font-mono text-xs text-cyan-400 mb-0.5">{mod.bonus}</div>
              {mod.drawback && mod.drawback !== 'None' && (
                <div className="font-mono text-xs text-red-500/80 mb-1">{mod.drawback}</div>
              )}
              {Object.keys(mod.statModifier).length > 0 && (
                <div className="flex flex-wrap gap-1">
                  {Object.entries(mod.statModifier).map(([stat, val]) => (
                    <span
                      key={stat}
                      className={`font-mono text-xs px-1 rounded ${
                        (val ?? 0) > 0 ? 'text-green-400 bg-green-950' : 'text-red-400 bg-red-950'
                      }`}
                    >
                      {stat.replace('_', ' ')} {(val ?? 0) > 0 ? '+' : ''}{val}
                    </span>
                  ))}
                </div>
              )}
            </button>
          )
        })}
      </div>
    </div>
  )
}
