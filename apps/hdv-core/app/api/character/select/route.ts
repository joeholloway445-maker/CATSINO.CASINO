import { type NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function POST(request: NextRequest) {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'unauthorized' }, { status: 401 })

  const { characterId } = await request.json()
  if (typeof characterId !== 'string') {
    return NextResponse.json({ error: 'characterId required' }, { status: 400 })
  }

  const { data: character, error } = await supabase
    .from('characters')
    .select('id')
    .eq('id', characterId)
    .eq('user_id', user.id)
    .single()

  if (error || !character) {
    return NextResponse.json({ error: 'character not found' }, { status: 404 })
  }

  const response = NextResponse.json({ ok: true })
  response.cookies.set('selected_character_id', characterId, {
    httpOnly: true,
    sameSite: 'lax',
    path: '/',
    maxAge: 60 * 60 * 24 * 30,
  })
  return response
}
