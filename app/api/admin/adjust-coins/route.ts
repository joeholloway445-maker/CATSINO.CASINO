import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function POST(request: Request) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    return NextResponse.json({ error: 'Not authenticated' }, { status: 401 })
  }

  const body = await request.json().catch(() => null)
  const targetUserId = body?.userId
  const amount = body?.amount

  if (typeof targetUserId !== 'string' || typeof amount !== 'number' || !Number.isFinite(amount)) {
    return NextResponse.json({ error: 'Invalid request' }, { status: 400 })
  }

  const { data, error } = await supabase.rpc('admin_adjust_coins', {
    p_user_id: targetUserId,
    p_amount: Math.trunc(amount),
  })

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 })
  }

  return NextResponse.json(data)
}
