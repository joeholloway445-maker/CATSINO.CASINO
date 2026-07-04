import { NextRequest, NextResponse } from 'next/server'
import { getAdminClient } from '@/lib/supabase/admin'

export async function GET() {
  const { data, error } = await getAdminClient().from('world_districts').select('*').order('id')
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ districts: data })
}

export async function PUT(req: NextRequest) {
  const body = await req.json()
  const { error } = await getAdminClient().from('world_districts').update({
    display_name: body.display_name, description: body.description,
    entry_fee: body.entry_fee, color_hex: body.color_hex,
    max_players: body.max_players, ambient_npc_count: body.ambient_npc_count,
    weather: body.weather, time_of_day: body.time_of_day,
    updated_at: new Date().toISOString(),
  }).eq('id', body.id)
  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json({ ok: true })
}
