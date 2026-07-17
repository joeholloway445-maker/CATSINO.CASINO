'use client'

import { Suspense, useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import StepFaction from '@/components/character-creation/StepFaction'
import StepRace from '@/components/character-creation/StepRace'
import StepFrame from '@/components/character-creation/StepFrame'
import StepPhysMod from '@/components/character-creation/StepPhysMod'
import StepCapture from '@/components/character-creation/StepCapture'
import CharacterPreview3D from '@/components/character-creation/CharacterPreview3D'
import { FACTIONS } from '@/lib/game/data/factions'
import { getRaceById } from '@/lib/game/data/races'
import { getFrameById } from '@/lib/game/data/frames'
import { getModById } from '@/lib/game/data/physicalMods'
import { createClient } from '@/lib/supabase/client'
import type { CharacterDraft, FactionId } from '@/types/character'

const STEPS = ['FACTION', 'RACE', 'FRAME', 'PHYSICAL MOD', 'CAPTURE', 'CONFIRM']

export default function CharacterCreationPage() {
  return (
    <Suspense fallback={null}>
      <CharacterCreationForm />
    </Suspense>
  )
}

function CharacterCreationForm() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const slotNumber = Number(searchParams.get('slot') ?? '1') || 1
  const [step, setStep] = useState(0)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [draft, setDraft] = useState<CharacterDraft>({
    faction: null,
    race: null,
    frame: null,
    physicalMod: null,
    username: '',
    portraitDataUrl: null,
  })

  const canAdvance = () => {
    if (step === 0) return draft.faction !== null
    if (step === 1) return draft.race !== null
    if (step === 2) return draft.frame !== null
    if (step === 3) return draft.physicalMod !== null
    return true
  }

  async function handleConfirm() {
    if (!draft.faction || !draft.race || !draft.frame || !draft.physicalMod) return
    setSaving(true)
    setError('')

    try {
      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) { router.push('/login'); return }

      const { data: inserted, error: charError } = await supabase
        .from('characters')
        .insert({
          user_id: user.id,
          faction: draft.faction,
          race: draft.race,
          frame: draft.frame,
          physical_mod: draft.physicalMod,
          slot_number: slotNumber,
        })
        .select('id')
        .single()

      if (charError && charError.code !== '23505') {
        setError(charError.message)
        setSaving(false)
        return
      }

      if (inserted) {
        await fetch('/api/character/select', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ characterId: inserted.id }),
        })
      }

      router.push('/game/extraliminal')
    } catch (e) {
      setError('Something went wrong. Try again.')
      setSaving(false)
    }
  }

  const faction = draft.faction ? FACTIONS[draft.faction] : null
  const race = (draft.race ? getRaceById(draft.race) : null) ?? null
  const frame = (draft.frame ? getFrameById(draft.frame) : null) ?? null
  const mod = (draft.physicalMod ? getModById(draft.physicalMod) : null) ?? null

  return (
    <div className="min-h-screen bg-[#0f0f1a] px-4 py-8">
      <div className="max-w-2xl mx-auto">
        {/* Progress */}
        <div className="flex items-center gap-2 mb-8">
          {STEPS.map((s, i) => (
            <div key={s} className="flex items-center gap-2 flex-1">
              <div
                className={`flex-1 h-0.5 ${i <= step ? 'bg-purple-600' : 'bg-slate-800'}`}
              />
              {i === STEPS.length - 1 ? null : (
                <div
                  className={`w-2 h-2 rounded-full flex-shrink-0 ${
                    i < step ? 'bg-purple-500' : i === step ? 'bg-purple-400 ring-2 ring-purple-800' : 'bg-slate-700'
                  }`}
                />
              )}
            </div>
          ))}
        </div>

        <div className="mb-2 font-mono text-xs text-purple-600 tracking-widest">
          STEP {step + 1} OF {STEPS.length} — {STEPS[step]}
        </div>

        {/* Live 3D preview — recolors/reshapes as Race/Frame/Mod are picked */}
        {step >= 1 && step <= 3 && (
          <div className="mb-6">
            <CharacterPreview3D race={race} frame={frame} mod={mod} />
          </div>
        )}

        {/* Step content */}
        <div className="rounded-xl border border-purple-900 bg-[#1a1a2e]/50 p-6 mb-6">
          {step === 0 && (
            <StepFaction
              value={draft.faction}
              onChange={(id: FactionId) => setDraft((d) => ({ ...d, faction: id }))}
            />
          )}
          {step === 1 && (
            <StepRace
              value={draft.race}
              onChange={(id) => setDraft((d) => ({ ...d, race: id }))}
            />
          )}
          {step === 2 && (
            <StepFrame
              value={draft.frame}
              onChange={(id) => setDraft((d) => ({ ...d, frame: id }))}
            />
          )}
          {step === 3 && (
            <StepPhysMod
              value={draft.physicalMod}
              onChange={(id) => setDraft((d) => ({ ...d, physicalMod: id }))}
            />
          )}
          {step === 4 && (
            <StepCapture
              slot={slotNumber}
              race={race}
              portraitDataUrl={draft.portraitDataUrl ?? null}
              onPortraitChange={(dataUrl) => setDraft((d) => ({ ...d, portraitDataUrl: dataUrl }))}
            />
          )}
          {step === 5 && (
            <div>
              <h2 className="font-mono text-lg text-slate-200 mb-4 tracking-wider">CONFIRM YOUR CHARACTER</h2>
              <div className="flex gap-4">
                {draft.portraitDataUrl && (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={draft.portraitDataUrl}
                    alt="Your avatar"
                    className="w-24 h-24 rounded-lg object-cover border border-purple-800 flex-shrink-0"
                  />
                )}
                <div className="space-y-3 flex-1">
                  {[
                    { label: 'FACTION', value: faction?.name, sub: faction?.origin },
                    { label: 'RACE', value: race?.name, sub: race?.texture.type },
                    { label: 'FRAME', value: frame?.name, sub: frame?.role },
                    { label: 'PHYSICAL MOD', value: mod?.name, sub: mod?.visualEffect },
                  ].map(({ label, value, sub }) => (
                    <div key={label} className="flex items-center gap-4 py-3 border-b border-purple-950">
                      <span className="font-mono text-xs text-purple-600 w-28">{label}</span>
                      <div>
                        <div className="font-mono text-sm text-slate-200">{value}</div>
                        <div className="font-mono text-xs text-slate-600">{sub}</div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <p className="font-mono text-xs text-slate-500 mt-4 leading-relaxed">
                Your faction is permanent. Race, Frame, and Physical Mod can be changed later with
                in-game currency. HOPE will be bonded to you from the moment you confirm.
              </p>

              {error && (
                <div className="mt-3 font-mono text-xs text-red-400 bg-red-950/50 border border-red-900 rounded px-3 py-2">
                  {error}
                </div>
              )}
            </div>
          )}
        </div>

        {/* Nav */}
        <div className="flex gap-3">
          {step > 0 && (
            <button
              onClick={() => setStep((s) => s - 1)}
              className="px-6 py-3 rounded-lg border border-slate-700 font-mono text-sm text-slate-400 hover:text-slate-200 hover:border-slate-500 transition-colors"
            >
              ← BACK
            </button>
          )}

          <div className="flex-1" />

          {step < STEPS.length - 1 ? (
            <button
              onClick={() => setStep((s) => s + 1)}
              disabled={!canAdvance()}
              className="px-8 py-3 rounded-lg bg-purple-700 hover:bg-purple-600 disabled:opacity-40 disabled:cursor-not-allowed font-mono text-sm text-white tracking-widest transition-colors border border-purple-500"
            >
              NEXT →
            </button>
          ) : (
            <button
              onClick={handleConfirm}
              disabled={saving}
              className="px-8 py-3 rounded-lg bg-purple-700 hover:bg-purple-600 disabled:opacity-50 font-mono text-sm text-white tracking-widest transition-colors border border-purple-500"
            >
              {saving ? 'BONDING HOPE...' : 'ENTER THE SPACE ✦'}
            </button>
          )}
        </div>
      </div>
    </div>
  )
}
