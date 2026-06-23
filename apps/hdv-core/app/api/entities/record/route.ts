import { type NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { getEntityById } from '@/lib/game/data/entities'

export async function POST(request: NextRequest) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const { entityId, caught } = await request.json()
  const entity = typeof entityId === 'string' ? getEntityById(entityId) : undefined
  if (!entity) return NextResponse.json({ error: 'unknown entity' }, { status: 400 })

  const { data: existing } = await supabase
    .from('player_entities')
    .select('*')
    .eq('user_id', user.id)
    .eq('entity_id', entity.id)
    .maybeSingle()

  if (!existing) {
    const { error } = await supabase.from('player_entities').insert({
      user_id: user.id,
      entity_id: entity.id,
      faction: entity.faction,
      entity_type: entity.role,
      count: caught ? 1 : 0,
      caught_at: caught ? new Date().toISOString() : null,
    })
    if (error) return NextResponse.json({ error: error.message }, { status: 500 })
    if (caught) await grantFragmentsForKill(supabase, entity.tier)
    return NextResponse.json({ ok: true })
  }

  if (caught) {
    const { error } = await supabase
      .from('player_entities')
      .update({
        count: existing.count + 1,
        caught_at: existing.caught_at ?? new Date().toISOString(),
      })
      .eq('id', existing.id)
    if (error) return NextResponse.json({ error: error.message }, { status: 500 })
    await grantFragmentsForKill(supabase, entity.tier)
  }

  return NextResponse.json({ ok: true })
}

// Fragments are the PvE reward currency (spec: "won via PvE quests and NPC
// kills"); every confirmed entity defeat grants some, scaled by tier. Best
// effort -- a missing currency ledger shouldn't block recording the kill.
async function grantFragmentsForKill(
  supabase: Awaited<ReturnType<typeof createClient>>,
  tier: number
) {
  await supabase.rpc('grant_currency', { p_currency: 'fragments', p_amount: tier * 2 })
}
