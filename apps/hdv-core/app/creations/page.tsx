import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { getEntityById } from '@/lib/game/data/entities'
import { blueprintCreationCost, blueprintChargeRate } from '@/types/ugc'
import CreationsWorkshop from '@/components/creations/CreationsWorkshop'
import type { PlayerEntity } from '@/types/entities'
import type { PlayerCreation, PlayerBlueprintCharges } from '@/types/ugc'

export default async function CreationsPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  const [{ data: character }, { data: playerEntities }, { data: playerCreations }, { data: playerCharges }] =
    await Promise.all([
      supabase.from('characters').select('*').eq('user_id', user.id).single(),
      supabase.from('player_entities').select('*').eq('user_id', user.id),
      supabase.from('player_creations').select('*').eq('user_id', user.id).order('created_at', { ascending: false }),
      supabase.from('player_blueprint_charges').select('*').eq('user_id', user.id),
    ])

  if (!character) redirect('/character-creation')

  const collection = (playerEntities ?? [])
    .map((pe: PlayerEntity) => {
      const entity = getEntityById(pe.entity_id)
      if (!entity) return null
      return {
        entity_id: pe.entity_id,
        name: entity.name,
        faction: entity.faction,
        role: entity.role,
        tier: entity.tier,
        count: pe.count,
        creationCost: blueprintCreationCost(entity.tier),
        chargeRate: blueprintChargeRate(entity.tier),
      }
    })
    .filter((item): item is NonNullable<typeof item> => item !== null)
    .sort((a, b) => a.name.localeCompare(b.name))

  const creations = (playerCreations ?? []).map((pc: PlayerCreation) => {
    const entity = getEntityById(pc.blueprint_id)
    return {
      id: pc.id,
      blueprint_id: pc.blueprint_id,
      name: pc.name,
      skin: pc.skin,
      power_level: pc.power_level,
      blueprintName: entity?.name ?? pc.blueprint_id,
      tier: entity?.tier ?? 1,
    }
  })

  const charges = (playerCharges ?? []).map((c: PlayerBlueprintCharges) => {
    const entity = getEntityById(c.blueprint_id)
    return {
      blueprint_id: c.blueprint_id,
      charge_count: c.charge_count,
      blueprintName: entity?.name ?? c.blueprint_id,
    }
  })

  return (
    <main className="min-h-screen px-6 py-10 max-w-4xl mx-auto">
      <div className="flex items-center gap-4 mb-10">
        <Link
          href="/profile"
          className="font-mono text-xs text-purple-500 hover:text-purple-300 transition-colors"
        >
          ← PROFILE
        </Link>
        <h1 className="font-mono text-xl text-slate-200 tracking-widest">BLUEPRINT WORKSHOP</h1>
      </div>

      <p className="font-mono text-xs text-slate-500 mb-8 leading-relaxed">
        Deconstruct duplicate copies of entities you&apos;ve collected. Reaching a blueprint&apos;s
        creation cost unlocks a new player creation with the same locked stats — name and skin are
        yours to choose. Extra duplicates convert into shared Charges, spendable on any creation
        built from that same blueprint.
      </p>

      <CreationsWorkshop collection={collection} creations={creations} charges={charges} />
    </main>
  )
}
