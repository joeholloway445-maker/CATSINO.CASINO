import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function POST(req: Request) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { killId } = await req.json()
  if (typeof killId !== 'string') {
    return NextResponse.json({ error: 'Invalid claim' }, { status: 400 })
  }

  const { data, error } = await supabase.rpc('claim_kill_loot', { p_kill_id: killId })

  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json(data)
}
