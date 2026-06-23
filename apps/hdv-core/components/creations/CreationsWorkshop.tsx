'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { FACTIONS } from '@/lib/game/data/factions'
import type { FactionId, EntityRole } from '@/types/character'
import type { CreationSkin } from '@/types/ugc'

interface CollectionItem {
  entity_id: string
  name: string
  faction: FactionId
  role: EntityRole
  tier: 1 | 2 | 3 | 4 | 5
  count: number
  creationCost: number
  chargeRate: number
}

interface CreationItem {
  id: string
  blueprint_id: string
  name: string
  skin: string
  power_level: number
  blueprintName: string
  tier: number
}

interface ChargeItem {
  blueprint_id: string
  charge_count: number
  blueprintName: string
}

const SKIN_OPTIONS: { id: CreationSkin; label: string }[] = [
  { id: 'custom', label: 'Custom' },
  { id: 'veiled_current', label: 'Veiled Current' },
  { id: 'sovereign_crown', label: 'Sovereign Crown' },
  { id: 'wildlands_ascendants', label: 'Wildlands Ascendants' },
]

export default function CreationsWorkshop({
  collection,
  creations,
  charges,
}: {
  collection: CollectionItem[]
  creations: CreationItem[]
  charges: ChargeItem[]
}) {
  const router = useRouter()
  const [busyKey, setBusyKey] = useState<string | null>(null)
  const [error, setError] = useState('')
  const [openCreate, setOpenCreate] = useState<string | null>(null)
  const [openCharge, setOpenCharge] = useState<string | null>(null)
  const [nameInputs, setNameInputs] = useState<Record<string, string>>({})
  const [skinInputs, setSkinInputs] = useState<Record<string, CreationSkin>>({})
  const [qtyInputs, setQtyInputs] = useState<Record<string, string>>({})
  const [spendInputs, setSpendInputs] = useState<Record<string, string>>({})

  async function handleCreate(entityId: string) {
    const name = (nameInputs[entityId] ?? '').trim()
    if (!name) {
      setError('Enter a name for your creation.')
      return
    }

    setBusyKey(`create-${entityId}`)
    setError('')

    const supabase = createClient()
    const { error: rpcError } = await supabase.rpc('deconstruct_for_creation', {
      p_entity_id: entityId,
      p_name: name,
      p_skin: skinInputs[entityId] ?? 'custom',
      p_visual: {},
    })

    setBusyKey(null)
    if (rpcError) {
      setError(rpcError.message)
      return
    }

    setOpenCreate(null)
    setNameInputs((v) => ({ ...v, [entityId]: '' }))
    router.refresh()
  }

  async function handleCharges(entityId: string) {
    const qty = parseInt(qtyInputs[entityId] ?? '', 10)
    if (!qty || qty <= 0) {
      setError('Enter a valid quantity.')
      return
    }

    setBusyKey(`charges-${entityId}`)
    setError('')

    const supabase = createClient()
    const { error: rpcError } = await supabase.rpc('deconstruct_for_charges', {
      p_entity_id: entityId,
      p_quantity: qty,
    })

    setBusyKey(null)
    if (rpcError) {
      setError(rpcError.message)
      return
    }

    setOpenCharge(null)
    setQtyInputs((v) => ({ ...v, [entityId]: '' }))
    router.refresh()
  }

  async function handleSpend(creationId: string) {
    const amount = parseInt(spendInputs[creationId] ?? '', 10)
    if (!amount || amount <= 0) {
      setError('Enter a valid amount.')
      return
    }

    setBusyKey(`spend-${creationId}`)
    setError('')

    const supabase = createClient()
    const { error: rpcError } = await supabase.rpc('spend_blueprint_charges', {
      p_creation_id: creationId,
      p_amount: amount,
    })

    setBusyKey(null)
    if (rpcError) {
      setError(rpcError.message)
      return
    }

    setSpendInputs((v) => ({ ...v, [creationId]: '' }))
    router.refresh()
  }

  return (
    <div className="space-y-10">
      {error && (
        <div className="font-mono text-xs text-red-400 bg-red-950/50 border border-red-900 rounded px-3 py-2">
          {error}
        </div>
      )}

      {/* Your Collection */}
      <section>
        <h2 className="font-mono text-sm text-purple-300 tracking-widest mb-4">YOUR COLLECTION</h2>
        {collection.length === 0 ? (
          <p className="font-mono text-xs text-slate-500">
            No entities collected yet. Explore Extraliminal Space to encounter companions.
          </p>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {collection.map((item) => (
              <div key={item.entity_id} className="rounded-xl border border-purple-800 bg-[#1a1a2e]/60 p-4">
                <div className="flex items-center justify-between mb-2">
                  <div>
                    <div className="font-mono text-slate-200 text-sm">{item.name}</div>
                    <div className="font-mono text-xs text-purple-600">
                      {FACTIONS[item.faction]?.name} · {item.role.toUpperCase()} · TIER {item.tier}
                    </div>
                  </div>
                  <div className="font-mono text-xs text-slate-400 text-right">
                    OWNED
                    <br />
                    <span className="text-lg text-slate-200">{item.count}</span>
                  </div>
                </div>

                <div className="font-mono text-xs text-slate-500 mb-3">
                  Create: {item.creationCost} copies · Charges: {item.chargeRate}/copy
                </div>

                <div className="flex gap-2">
                  <button
                    onClick={() => {
                      setOpenCreate(openCreate === item.entity_id ? null : item.entity_id)
                      setOpenCharge(null)
                      setError('')
                    }}
                    disabled={item.count < item.creationCost}
                    className="flex-1 py-2 rounded-lg border border-purple-700 font-mono text-xs text-purple-300 hover:bg-purple-900/40 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                  >
                    DECONSTRUCT → CREATION
                  </button>
                  <button
                    onClick={() => {
                      setOpenCharge(openCharge === item.entity_id ? null : item.entity_id)
                      setOpenCreate(null)
                      setError('')
                    }}
                    disabled={item.count < 1}
                    className="flex-1 py-2 rounded-lg border border-purple-700 font-mono text-xs text-purple-300 hover:bg-purple-900/40 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                  >
                    DECONSTRUCT → CHARGES
                  </button>
                </div>

                {openCreate === item.entity_id && (
                  <div className="mt-3 space-y-2 border-t border-purple-900 pt-3">
                    <input
                      type="text"
                      placeholder="Creation name"
                      value={nameInputs[item.entity_id] ?? ''}
                      onChange={(e) => setNameInputs((v) => ({ ...v, [item.entity_id]: e.target.value }))}
                      className="w-full bg-[#0f0f1a] border border-purple-900 rounded px-3 py-2 font-mono text-xs text-slate-200 focus:outline-none focus:border-purple-500"
                    />
                    <select
                      value={skinInputs[item.entity_id] ?? 'custom'}
                      onChange={(e) =>
                        setSkinInputs((v) => ({ ...v, [item.entity_id]: e.target.value as CreationSkin }))
                      }
                      className="w-full bg-[#0f0f1a] border border-purple-900 rounded px-3 py-2 font-mono text-xs text-slate-200 focus:outline-none focus:border-purple-500"
                    >
                      {SKIN_OPTIONS.map((s) => (
                        <option key={s.id} value={s.id}>
                          {s.label}
                        </option>
                      ))}
                    </select>
                    <button
                      onClick={() => handleCreate(item.entity_id)}
                      disabled={busyKey === `create-${item.entity_id}`}
                      className="w-full py-2 rounded-lg bg-purple-700 hover:bg-purple-600 disabled:opacity-50 font-mono text-xs text-white tracking-widest transition-colors border border-purple-500"
                    >
                      {busyKey === `create-${item.entity_id}`
                        ? 'DECONSTRUCTING...'
                        : `CONFIRM (−${item.creationCost} ${item.name})`}
                    </button>
                  </div>
                )}

                {openCharge === item.entity_id && (
                  <div className="mt-3 space-y-2 border-t border-purple-900 pt-3">
                    <input
                      type="number"
                      min={1}
                      max={item.count}
                      placeholder={`Quantity (max ${item.count})`}
                      value={qtyInputs[item.entity_id] ?? ''}
                      onChange={(e) => setQtyInputs((v) => ({ ...v, [item.entity_id]: e.target.value }))}
                      className="w-full bg-[#0f0f1a] border border-purple-900 rounded px-3 py-2 font-mono text-xs text-slate-200 focus:outline-none focus:border-purple-500"
                    />
                    <button
                      onClick={() => handleCharges(item.entity_id)}
                      disabled={busyKey === `charges-${item.entity_id}`}
                      className="w-full py-2 rounded-lg bg-purple-700 hover:bg-purple-600 disabled:opacity-50 font-mono text-xs text-white tracking-widest transition-colors border border-purple-500"
                    >
                      {busyKey === `charges-${item.entity_id}`
                        ? 'DECONSTRUCTING...'
                        : `CONFIRM (+${item.chargeRate}/copy)`}
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </section>

      {/* Your Creations */}
      <section>
        <h2 className="font-mono text-sm text-purple-300 tracking-widest mb-4">YOUR CREATIONS</h2>
        {creations.length === 0 ? (
          <p className="font-mono text-xs text-slate-500">
            No creations yet. Deconstruct collected entities above to build your first.
          </p>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {creations.map((c) => {
              const pool = charges.find((ch) => ch.blueprint_id === c.blueprint_id)
              const available = pool?.charge_count ?? 0
              return (
                <div key={c.id} className="rounded-xl border border-purple-800 bg-[#1a1a2e]/60 p-4">
                  <div className="font-mono text-slate-200 text-sm">{c.name}</div>
                  <div className="font-mono text-xs text-purple-600 mb-2">
                    Based on {c.blueprintName} · TIER {c.tier} · Skin: {c.skin}
                  </div>
                  <div className="font-mono text-xs text-slate-400 mb-3">
                    POWER LEVEL: <span className="text-slate-200">{c.power_level}</span>
                    {' · '}
                    AVAILABLE CHARGES: <span className="text-slate-200">{available}</span>
                  </div>
                  <div className="flex gap-2">
                    <input
                      type="number"
                      min={1}
                      max={available}
                      placeholder="Amount"
                      value={spendInputs[c.id] ?? ''}
                      onChange={(e) => setSpendInputs((v) => ({ ...v, [c.id]: e.target.value }))}
                      className="flex-1 bg-[#0f0f1a] border border-purple-900 rounded px-3 py-2 font-mono text-xs text-slate-200 focus:outline-none focus:border-purple-500"
                    />
                    <button
                      onClick={() => handleSpend(c.id)}
                      disabled={available < 1 || busyKey === `spend-${c.id}`}
                      className="px-4 py-2 rounded-lg border border-purple-700 font-mono text-xs text-purple-300 hover:bg-purple-900/40 disabled:opacity-30 disabled:cursor-not-allowed transition-colors"
                    >
                      {busyKey === `spend-${c.id}` ? '...' : 'SPEND CHARGES'}
                    </button>
                  </div>
                </div>
              )
            })}
          </div>
        )}
      </section>

      {/* Charge Pools */}
      <section>
        <h2 className="font-mono text-sm text-purple-300 tracking-widest mb-4">BLUEPRINT CHARGE POOLS</h2>
        {charges.length === 0 ? (
          <p className="font-mono text-xs text-slate-500">No charges banked yet.</p>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            {charges.map((c) => (
              <div
                key={c.blueprint_id}
                className="rounded-lg bg-[#0f0f1a] border border-purple-900 p-3 text-center"
              >
                <div className="font-mono text-xs text-purple-600 mb-1 truncate">{c.blueprintName}</div>
                <div className="font-mono text-slate-200 text-xl">{c.charge_count}</div>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  )
}
