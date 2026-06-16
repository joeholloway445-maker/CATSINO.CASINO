import { createClient } from '@supabase/supabase-js'
import { NextRequest, NextResponse } from 'next/server'

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

export async function GET() {
  const { data, error } = await supabase.from('world_dialogues').select('*').order('dialogue_id')
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ dialogues: data })
}

export async function POST(req: NextRequest) {
  const body = await req.json()
  const { data, error } = await supabase.from('world_dialogues').insert({
    dialogue_id: body.dialogue_id, npc_id: body.npc_id || null,
    start_node: body.start_node || 'greeting', nodes: body.nodes || [],
  }).select().single()
  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json({ dialogue: data })
}

export async function PUT(req: NextRequest) {
  const body = await req.json()
  const { error } = await supabase.from('world_dialogues').update({
    start_node: body.start_node, nodes: body.nodes || [],
    updated_at: new Date().toISOString(),
  }).eq('dialogue_id', body.dialogue_id)
  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json({ ok: true })
}

export async function DELETE(req: NextRequest) {
  const id = new URL(req.url).searchParams.get('id')
  if (!id) return NextResponse.json({ error: 'id required' }, { status: 400 })
  const { error } = await supabase.from('world_dialogues').delete().eq('dialogue_id', id)
  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json({ ok: true })
}
