'use client'

import { useState } from 'react'
import type { Race, Frame, PhysicalMod } from '@/types/character'
import type { Entity } from '@/types/entities'
import { OMNIDEX_FRAME_COUNT, OMNIDEX_RACE_COUNT, OMNIDEX_MOD_COUNT } from '@/lib/game/data/omniDexRegistry'

type Tab = 'races' | 'frames' | 'mods' | 'entities' | 'companions'

export interface OmniDexCompanion {
  id: string
  name: string
  faction: string
  rarity?: string | number
  lore?: string
}

interface Props {
  races: Race[]
  frames: Frame[]
  mods: PhysicalMod[]
  entities: Entity[]
  companions?: OmniDexCompanion[]
  unlockedRaces: string[]
  unlockedFrames: string[]
  unlockedMods: string[]
  discoveredEntityIds: string[]
  caughtEntityIds: string[]
  unlockedCompanionIds?: string[]
}

const TABS: { key: Tab; label: string }[] = [
  { key: 'races', label: 'RACES' },
  { key: 'frames', label: 'FRAMES' },
  { key: 'mods', label: 'MODS' },
  { key: 'entities', label: 'ENTITIES' },
  { key: 'companions', label: 'COMPANIONS' },
]

function SilhouetteCard({ name }: { name: string }) {
  return (
    <div className="rounded-lg border border-slate-800 bg-[#13131f] p-4 flex flex-col items-center justify-center h-40">
      <div className="w-12 h-12 rounded-full bg-slate-800" />
      <div className="mt-3 font-mono text-xs text-slate-600">??? — {name.replace(/./g, '?')}</div>
      <div className="font-mono text-[10px] text-slate-700 mt-1">UNDISCOVERED</div>
    </div>
  )
}

function UnlockedCard({
  name,
  sub,
  description,
  accentHex,
  descriptionLocked,
}: {
  name: string
  sub: string
  description: string
  accentHex: string
  descriptionLocked?: boolean
}) {
  return (
    <div
      className="rounded-lg border bg-[#1a1a2e] p-4 h-40 flex flex-col"
      style={{ borderColor: accentHex }}
    >
      <div className="font-mono text-sm text-slate-200">{name}</div>
      <div className="font-mono text-[10px] text-slate-500 mb-2">{sub}</div>
      {descriptionLocked ? (
        <div className="font-mono text-[11px] text-slate-600 italic">Lore locked — catch this entity to unlock.</div>
      ) : (
        <div className="font-mono text-[11px] text-slate-400 overflow-hidden">{description}</div>
      )}
    </div>
  )
}

export default function OmniDexBrowser({
  races,
  frames,
  mods,
  entities,
  companions = [],
  unlockedRaces,
  unlockedFrames,
  unlockedMods,
  discoveredEntityIds,
  caughtEntityIds,
  unlockedCompanionIds = [],
}: Props) {
  const [tab, setTab] = useState<Tab>('races')

  const unlockedRaceSet = new Set(unlockedRaces)
  const unlockedFrameSet = new Set(unlockedFrames)
  const unlockedModSet = new Set(unlockedMods)
  const discoveredSet = new Set(discoveredEntityIds)
  const caughtSet = new Set(caughtEntityIds)
  const unlockedCompanionSet = new Set(unlockedCompanionIds)

  const countHint =
    tab === 'races'
      ? `${races.length}/${OMNIDEX_RACE_COUNT}`
      : tab === 'frames'
        ? `${frames.length}/${OMNIDEX_FRAME_COUNT}`
        : tab === 'mods'
          ? `${mods.length}/${OMNIDEX_MOD_COUNT}`
          : tab === 'entities'
            ? `${entities.length}`
            : `${companions.length}`

  return (
    <div>
      <div className="flex flex-wrap items-center gap-2 mb-6">
        {TABS.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`px-4 py-2 rounded-lg font-mono text-xs tracking-widest border transition-colors ${
              tab === t.key
                ? 'border-purple-500 text-purple-300 bg-purple-950/40'
                : 'border-slate-800 text-slate-500 hover:text-slate-300'
            }`}
          >
            {t.label}
          </button>
        ))}
        <span className="ml-auto font-mono text-[10px] text-slate-600 tracking-widest">
          {countHint}
        </span>
      </div>

      {tab === 'races' && (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
          {races.map((r) =>
            unlockedRaceSet.has(r.id) ? (
              <UnlockedCard key={r.id} name={r.name} sub={r.faction} description={r.description} accentHex={r.texture.primaryColor} />
            ) : (
              <SilhouetteCard key={r.id} name={r.name} />
            ),
          )}
        </div>
      )}

      {tab === 'frames' && (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
          {frames.map((f) =>
            unlockedFrameSet.has(f.id) ? (
              <UnlockedCard key={f.id} name={f.name} sub={f.role} description={f.description} accentHex="#6366f1" />
            ) : (
              <SilhouetteCard key={f.id} name={f.name} />
            ),
          )}
        </div>
      )}

      {tab === 'mods' && (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
          {mods.map((m) =>
            unlockedModSet.has(m.id) ? (
              <UnlockedCard key={m.id} name={m.name} sub={m.visualEffect} description={m.description} accentHex="#22c55e" />
            ) : (
              <SilhouetteCard key={m.id} name={m.name} />
            ),
          )}
        </div>
      )}

      {tab === 'entities' && (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
          {entities.map((e) => {
            if (!discoveredSet.has(e.id)) return <SilhouetteCard key={e.id} name={e.name} />
            return (
              <UnlockedCard
                key={e.id}
                name={`${e.name} — ${e.title}`}
                sub={`${e.faction} · T${e.tier} ${e.role.toUpperCase()}`}
                description={e.description}
                accentHex="#a855f7"
                descriptionLocked={!caughtSet.has(e.id)}
              />
            )
          })}
        </div>
      )}

      {tab === 'companions' && (
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
          {companions.length === 0 ? (
            <div className="col-span-full font-mono text-xs text-slate-600">
              Companion roster syncs from the Godot OmniDex registry in-client.
            </div>
          ) : (
            companions.map((c) =>
              unlockedCompanionSet.has(c.id) || unlockedCompanionSet.size === 0 ? (
                <UnlockedCard
                  key={c.id}
                  name={c.name}
                  sub={`${c.faction}${c.rarity != null ? ` · R${c.rarity}` : ''}`}
                  description={c.lore ?? c.id}
                  accentHex="#38bdf8"
                />
              ) : (
                <SilhouetteCard key={c.id} name={c.name} />
              ),
            )
          )}
        </div>
      )}
    </div>
  )
}
