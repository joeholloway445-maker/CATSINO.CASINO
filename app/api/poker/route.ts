import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

const VALID_BETS = new Set([10, 25, 50, 100, 250, 500, 1000])

export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const { bet, held_indices = [], phase = 'deal' } = body

    if (!VALID_BETS.has(bet)) {
      return NextResponse.json({ error: 'Invalid bet' }, { status: 400 })
    }
    if (!['deal', 'draw'].includes(phase)) {
      return NextResponse.json({ error: 'Invalid phase' }, { status: 400 })
    }

    const supabase = await createClient()
    const { data, error } = await supabase.rpc('play_poker', {
      p_bet: bet,
      p_held_indices: held_indices,
      p_phase: phase,
    })

    if (error) {
      console.error('play_poker rpc error:', error)
      return NextResponse.json({ error: error.message }, { status: 400 })
    }

    return NextResponse.json(data)
  } catch (e) {
    return NextResponse.json({ error: 'Server error' }, { status: 500 })
  }
}
