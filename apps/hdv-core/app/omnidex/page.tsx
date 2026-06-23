import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { RACES } from '@/lib/game/data/races'
import { FRAMES } from '@/lib/game/data/frames'
import { PHYSICAL_MODS } from '@/lib/game/data/physicalMods'
import { ALL_ENTITIES } from '@/lib/game/data/entities'
import OmniDexBrowser from '@/components/omnidex/OmniDexBrowser'
import type { PlayerEntity } from '@/types/entities'

export default async function OmniDexPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const [{ data: characters }, { data: playerEntities }] = await Promise.all([
    supabase.from('characters').select('race, frame, physical_mod').eq('user_id', user.id),
    supabase.from('player_entities').select('*').eq('user_id', user.id),
  ])

  const unlockedRaces = new Set((characters ?? []).map((c) => c.race))
  const unlockedFrames = new Set((characters ?? []).map((c) => c.frame))
  const unlockedMods = new Set((characters ?? []).map((c) => c.physical_mod))

  const discoveredEntities = new Map<string, PlayerEntity>(
    (playerEntities ?? []).map((pe: PlayerEntity) => [pe.entity_id, pe]),
  )

  return (
    <div className="min-h-screen bg-[#0f0f1a] px-4 py-8">
      <div className="max-w-5xl mx-auto">
        <div className="flex items-center justify-between mb-6">
          <h1 className="font-mono text-xl text-purple-400 tracking-widest">OMNIDEX</h1>
          <Link href="/character-select" className="font-mono text-xs text-purple-500 hover:text-purple-300">
            ← BACK
          </Link>
        </div>

        <OmniDexBrowser
          races={RACES}
          frames={FRAMES}
          mods={PHYSICAL_MODS}
          entities={ALL_ENTITIES}
          unlockedRaces={Array.from(unlockedRaces)}
          unlockedFrames={Array.from(unlockedFrames)}
          unlockedMods={Array.from(unlockedMods)}
          discoveredEntityIds={Array.from(discoveredEntities.keys())}
          caughtEntityIds={Array.from(discoveredEntities.values())
            .filter((pe) => pe.caught_at)
            .map((pe) => pe.entity_id)}
        />
      </div>
    </div>
  )
}
