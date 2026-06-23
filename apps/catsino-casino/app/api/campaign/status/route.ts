import { NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function GET() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })

  const { data: campaign, error: campaignError } = await supabase
    .from('pvp_campaigns')
    .select('id, label, status, started_at')
    .eq('status', 'active')
    .maybeSingle()
  if (campaignError) return NextResponse.json({ error: campaignError.message }, { status: 500 })
  if (!campaign) return NextResponse.json({ campaign: null })

  const { data: kills } = await supabase
    .from('pvp_campaign_kills')
    .select('id, killer_id, victim_id, killer_faction, victim_faction, zone_id, dropped_tokens, claimed_by, claimed_at, occurred_at')
    .eq('campaign_id', campaign.id)
    .order('occurred_at', { ascending: false })
    .limit(200)

  const factionScores: Record<string, number> = {}
  for (const k of kills ?? []) {
    factionScores[k.killer_faction] = (factionScores[k.killer_faction] ?? 0) + 1
  }

  const lootable = (kills ?? []).filter((k) => k.claimed_by === null && k.dropped_tokens > 0)

  return NextResponse.json({
    campaign,
    factionScores,
    recentKills: (kills ?? []).slice(0, 50),
    lootable,
  })
}
