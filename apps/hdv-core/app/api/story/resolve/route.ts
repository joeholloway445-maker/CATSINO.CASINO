import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function POST(req: Request) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { arcId, winningChoiceId } = await req.json()
  if (typeof arcId !== 'string' || typeof winningChoiceId !== 'string') {
    return NextResponse.json({ error: 'Invalid request' }, { status: 400 })
  }

  const { data, error } = await supabase.rpc('resolve_story_arc', {
    p_arc_id: arcId,
    p_winning_choice_id: winningChoiceId,
  })
  if (error) return NextResponse.json({ error: error.message }, { status: 400 })
  return NextResponse.json(data)
}
