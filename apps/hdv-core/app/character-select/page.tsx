import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { getRaceById } from '@/lib/game/data/races'
import { getFrameById } from '@/lib/game/data/frames'
import CharacterSelectClient from '@/components/character-select/CharacterSelectClient'
import type { Character } from '@/types/character'

export default async function CharacterSelectPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const [{ data: profile }, { data: characters }, { data: currencies }] = await Promise.all([
    supabase.from('profiles').select('character_slots').eq('id', user.id).single(),
    supabase.from('characters').select('*').eq('user_id', user.id).order('slot_number'),
    supabase.from('player_currencies').select('*').eq('user_id', user.id).single(),
  ])

  const slots = profile?.character_slots ?? 3

  const characterSummaries = (characters ?? []).map((c: Character & { slot_number: number }) => ({
    id: c.id,
    slotNumber: c.slot_number,
    faction: c.faction,
    raceName: getRaceById(c.race)?.name ?? c.race,
    frameName: getFrameById(c.frame)?.name ?? c.frame,
    prestigeLevel: c.prestige_level,
  }))

  return (
    <CharacterSelectClient
      slots={slots}
      characters={characterSummaries}
      coin={currencies?.coin ?? 0}
    />
  )
}
