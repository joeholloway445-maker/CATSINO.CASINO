import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function POST(req: Request) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { victimId, zoneId } = await req.json()
  if (typeof victimId !== 'string') {
    return NextResponse.json({ error: 'Invalid kill' }, { status: 400 })
  }

  const { data, error } = await supabase.rpc('record_pvp_kill', {
    p_victim_id: victimId,
    p_zone_id: typeof zoneId === 'string' ? zoneId : null,
  })

  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json(data)
}
