import ExtraliminalGameLoader from '@/components/game/ExtraliminalGameLoader'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { cookies } from 'next/headers'

export default async function ExtraliminalPage() {
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

  const [{ data: character }, { data: currencies }] = await Promise.all([
    supabase.from('characters').select('*').eq('id', selectedCharacterId).eq('user_id', user.id).single(),
    supabase.from('player_currencies').select('*').eq('user_id', user.id).single(),
  ])

  if (!character) redirect('/character-select')

  return (
    <div className="w-full h-screen overflow-hidden bg-[#0f0f1a]">
      <ExtraliminalGameLoader
        playerData={{
          faction: character.faction,
          race: character.race,
          frame: character.frame,
          prestige: character.prestige_level,
          currencies: currencies ?? {
            coin: 0, chip: 0, fragments: 0, tokens: 0, charges: 0, renown: 0,
          },
        }}
      />
    </div>
  )
}
