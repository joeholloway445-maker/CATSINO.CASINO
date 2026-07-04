import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function POST(req: Request) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { arcId, choiceId, amount, currency } = await req.json()
  if (typeof arcId !== 'string' || typeof choiceId !== 'string' || !Number.isInteger(amount) || amount <= 0) {
    return NextResponse.json({ error: 'Invalid wager' }, { status: 400 })
  }

  const requested = currency === 'renown' ? 'renown' : 'chip'

  const { data, error } = await supabase.rpc('place_story_wager', {
    p_arc_id: arcId,
    p_choice_id: choiceId,
    p_currency: requested,
    p_amount: amount,
  })

  // If the player asked to wager chips but is out of chips, fall back to
  // renown automatically rather than just failing the wager outright.
  if (error && requested === 'chip' && currency !== 'renown' && /insufficient/i.test(error.message)) {
    const fallback = await supabase.rpc('place_story_wager', {
      p_arc_id: arcId,
      p_choice_id: choiceId,
      p_currency: 'renown',
      p_amount: amount,
    })
    if (fallback.error) return NextResponse.json({ error: fallback.error.message }, { status: 400 })
    return NextResponse.json({ ...fallback.data, fellBackToRenown: true })
  }

  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json(data)
}
