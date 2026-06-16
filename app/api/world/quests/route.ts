import { createClient } from '@supabase/supabase-js'
import { NextRequest, NextResponse } from 'next/server'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

export async function GET() {
  const { data, error } = await supabase.from('world_quests').select('*').order('type')
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ quests: data })
}

export async function POST(req: NextRequest) {
  const body = await req.json()
  const { data, error } = await supabase.from('world_quests').insert({
    id: body.id, title: body.title, type: body.type, description: body.description,
    giver_npc: body.giver_npc || '', district: body.district,
    prerequisites: body.prerequisites || [],
    objectives: body.objectives || [],
    reward_coins: body.reward_coins || 0, reward_xp: body.reward_xp || 0,
    unlock_companion: body.unlock_companion || '', next_quest: body.next_quest || '',
  }).select().single()
  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json({ quest: data, id: data.id })
}

export async function PUT(req: NextRequest) {
  const body = await req.json()
  const { error } = await supabase.from('world_quests').update({
    title: body.title, type: body.type, description: body.description,
    giver_npc: body.giver_npc, district: body.district,
    prerequisites: body.prerequisites || [],
    objectives: body.objectives || [],
    reward_coins: body.reward_coins, reward_xp: body.reward_xp,
    unlock_companion: body.unlock_companion, next_quest: body.next_quest,
    updated_at: new Date().toISOString(),
  }).eq('id', body.id)
  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json({ ok: true })
}

export async function DELETE(req: NextRequest) {
  const id = new URL(req.url).searchParams.get('id')
  if (!id) return NextResponse.json({ error: 'id required' }, { status: 400 })
  const { error } = await supabase.from('world_quests').delete().eq('id', id)
  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json({ ok: true })
}
