import { createClient } from '@supabase/supabase-js'
import { NextRequest, NextResponse } from 'next/server'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

export async function GET() {
  const { data, error } = await supabase.from('world_npcs').select('*').order('district')
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ npcs: data })
}

export async function POST(req: NextRequest) {
  const body = await req.json()
  const row = {
    id: body.id, name: body.name, district: body.district, role: body.role,
    faction: body.faction, emoji: body.emoji, greeting: body.greeting,
    shop_id: body.shop_id || '', dialogue_id: body.dialogue_id || '',
    pos_x: body.pos_x || 0, pos_y: body.pos_y || 0, pos_z: body.pos_z || 0,
    quest_ids: body.quest_ids || [],
  }
  const { data, error } = await supabase.from('world_npcs').insert(row).select().single()
  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json({ npc: data, id: data.id })
}

export async function PUT(req: NextRequest) {
  const body = await req.json()
  const { error } = await supabase.from('world_npcs').update({
    name: body.name, district: body.district, role: body.role, faction: body.faction,
    emoji: body.emoji, greeting: body.greeting, shop_id: body.shop_id,
    dialogue_id: body.dialogue_id, pos_x: body.pos_x, pos_y: body.pos_y, pos_z: body.pos_z,
    quest_ids: body.quest_ids || [], updated_at: new Date().toISOString(),
  }).eq('id', body.id)
  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json({ ok: true })
}

export async function DELETE(req: NextRequest) {
  const id = new URL(req.url).searchParams.get('id')
  if (!id) return NextResponse.json({ error: 'id required' }, { status: 400 })
  const { error } = await supabase.from('world_npcs').delete().eq('id', id)
  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json({ ok: true })
}
