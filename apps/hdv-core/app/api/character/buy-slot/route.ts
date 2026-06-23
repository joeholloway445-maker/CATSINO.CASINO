import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

const SLOT_COST_COIN = 500

export async function POST() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const { data: profile } = await supabase
    .from('profiles')
    .select('character_slots')
    .eq('id', user.id)
    .single()

  if (!profile) {
    return NextResponse.json({ error: 'profile not found' }, { status: 404 })
  }

  const { error: currencyError } = await supabase.rpc('spend_currency', {
    p_currency: 'coin',
    p_amount: SLOT_COST_COIN,
  })

  if (currencyError) {
    return NextResponse.json({ error: currencyError.message }, { status: 400 })
  }

  const { error: slotError } = await supabase
    .from('profiles')
    .update({ character_slots: profile.character_slots + 1 })
    .eq('id', user.id)

  if (slotError) {
    return NextResponse.json({ error: slotError.message }, { status: 500 })
  }

  return NextResponse.json({ ok: true, slots: profile.character_slots + 1 })
}
