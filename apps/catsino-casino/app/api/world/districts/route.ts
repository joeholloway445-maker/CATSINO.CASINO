import { NextRequest, NextResponse } from 'next/server'
import { getAdminClient } from '@/lib/supabase/admin'
import { createClient } from '@/lib/supabase/server'

async function requireAdmin() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return null
  const { data: profile } = await supabase.from('profiles').select('is_admin').eq('id', user.id).single()
  return profile?.is_admin ? user : null
}

export async function GET() {
  const { data, error } = await getAdminClient().from('world_districts').select('*').order('id')
  if (error) return NextResponse.json({ error: error.message }, { status: 500 })
  return NextResponse.json({ districts: data })
}

export async function PUT(req: NextRequest) {
  if (!await requireAdmin()) return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
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
