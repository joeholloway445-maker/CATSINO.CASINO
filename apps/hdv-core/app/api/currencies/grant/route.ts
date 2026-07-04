import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

const VALID_CURRENCIES = ['coin', 'chip', 'fragments', 'tokens', 'charges', 'renown']

export async function POST(req: Request) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { currency, amount } = await req.json()
  if (!VALID_CURRENCIES.includes(currency) || !Number.isInteger(amount) || amount <= 0) {
    return NextResponse.json({ error: 'Invalid currency or amount' }, { status: 400 })
  }

  const { data, error } = await supabase.rpc('grant_currency', {
    p_currency: currency,
    p_amount: amount,
  })
  if (error) return NextResponse.json({ error: error.message }, { status: 400 })

  return NextResponse.json(data)
}
