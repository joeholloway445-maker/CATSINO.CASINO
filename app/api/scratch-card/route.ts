import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

const VALID_BETS = new Set([10, 25, 50, 100, 250, 500, 1000])

export async function POST(request: Request) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    return NextResponse.json({ error: 'Not authenticated' }, { status: 401 })
  }

  const body = await request.json().catch(() => null)
  const bet = body?.bet

  if (typeof bet !== 'number' || !VALID_BETS.has(bet)) {
    return NextResponse.json({ error: 'Invalid bet amount' }, { status: 400 })
  }

  const { data, error } = await supabase.rpc('scratch_card', { p_bet: bet })

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 })
  }

  return NextResponse.json(data)
}
