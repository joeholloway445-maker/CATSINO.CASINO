import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

const VALID_BETS = new Set([10, 25, 50, 100, 250, 500, 1000])
const VALID_ACTIONS = new Set(['deal', 'hit', 'stand', 'double'])

export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const { action, bet, game_state } = body

    if (!VALID_ACTIONS.has(action)) {
      return NextResponse.json({ error: 'Invalid action' }, { status: 400 })
    }
    if (action === 'deal' && !VALID_BETS.has(bet)) {
      return NextResponse.json({ error: 'Invalid bet' }, { status: 400 })
    }

    const supabase = await createClient()
    const { data, error } = await supabase.rpc('play_blackjack', {
      p_action: action,
      p_bet: bet ?? 0,
      p_game_state: game_state ?? null,
    })

    if (error) {
      console.error('play_blackjack rpc error:', error)
      return NextResponse.json({ error: error.message }, { status: 400 })
    }

    return NextResponse.json(data)
  } catch (e) {
    return NextResponse.json({ error: 'Server error' }, { status: 500 })
  }
}
