import GameLoader from '@/components/GameLoader'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { cookies } from 'next/headers'

export default async function GamePage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const cookieStore = await cookies()
  const selectedCharacterId = cookieStore.get('selected_character_id')?.value

  const { data: anyCharacter } = await supabase
    .from('characters')
    .select('id')
    .eq('user_id', user.id)
    .limit(1)
    .maybeSingle()

  if (!anyCharacter) redirect('/character-creation')
  if (!selectedCharacterId) redirect('/character-select')

  return (
    <div className="w-full h-screen overflow-hidden bg-[#0f0f1a]">
      <GameLoader />
    </div>
  )
}
