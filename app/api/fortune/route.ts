import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

const VALID_BETS = new Set([10, 25, 50, 100, 250, 500, 1000])

export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const { bet } = body

    if (!VALID_BETS.has(bet)) {
      return NextResponse.json({ error: 'Invalid bet' }, { status: 400 })
    }

    const supabase = await createClient()
    const { data, error } = await supabase.rpc('draw_fortune', { p_bet: bet })

    if (error) {
      console.error('draw_fortune rpc error:', error)
      return NextResponse.json({ error: error.message }, { status: 400 })
    }

    return NextResponse.json(data)
  } catch (e) {
    return NextResponse.json({ error: 'Server error' }, { status: 500 })
  }
}
