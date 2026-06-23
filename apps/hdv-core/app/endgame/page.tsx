import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

interface RoadmapEntry {
  key: string
  title: string
  blurb: string
  href?: string
}

// Tracks the long-term endgame roadmap. Entries only get an `href` once
// they're actually playable -- everything else renders locked so the list
// is honest about what exists vs. what's planned.
const ROADMAP: RoadmapEntry[] = [
  {
    key: 'storyline',
    title: 'Seasonal Storyline',
    blurb: 'Player-voted overarching plots, one new arc per season.',
    href: '/story',
  },
  {
    key: 'campaigns',
    title: 'PvP Campaigns',
    blurb: 'Always-on, open-world faction warfare -- no closed zones, kills count 24/7. Everything else PvP feeds into this.',
    href: '/campaign',
  },
  { key: 'duels', title: '1v1 / 2v2 PvP', blurb: 'Small-scale ranked duels and team skirmishes.' },
  { key: 'moba', title: 'MOBA', blurb: 'Lane/jungle/objective modes, Mobile-Legends-style.' },
  { key: 'conflict', title: 'Conflict', blurb: 'Classic team shooter modes -- deathmatch, domination, and more.' },
  { key: 'zombies', title: 'Zombies', blurb: 'Wave-survival co-op with our own tiered entities.' },
  { key: 'dungeons', title: 'Dungeons & Boss Fights', blurb: 'ESO/WoW-style instanced encounters and raid bosses (PvE -- closed/instanced zones).' },
  { key: 'ugc', title: 'UGC', blurb: 'Player-created content, building on the existing companion blueprint system.' },
]

export default async function EndgamePage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  return (
    <div className="min-h-screen bg-[#0f0f1a] px-4 py-8">
      <div className="max-w-3xl mx-auto">
        <div className="flex items-center justify-between mb-2">
          <h1 className="font-mono text-xl text-purple-400 tracking-widest">ENDGAME ROADMAP</h1>
          <Link href="/character-select" className="font-mono text-xs text-purple-500 hover:text-purple-300">
            ← BACK
          </Link>
        </div>
        <p className="font-mono text-xs text-purple-600 mb-6">
          Everything below is the plan. Locked entries aren&apos;t built yet -- they show up so the roadmap stays honest.
        </p>

        <div className="space-y-2">
          {ROADMAP.map((entry) => {
            const card = (
              <div
                className={`border rounded-lg px-4 py-3 flex items-center justify-between ${
                  entry.href
                    ? 'border-purple-700 bg-purple-950/30 hover:bg-purple-950/50 transition-colors'
                    : 'border-gray-800 bg-gray-900/40 opacity-60'
                }`}
              >
                <div>
                  <p className={`text-sm font-bold ${entry.href ? 'text-purple-200' : 'text-gray-400'}`}>
                    {entry.title}
                  </p>
                  <p className="text-xs text-gray-500 mt-0.5">{entry.blurb}</p>
                </div>
                <span className={`text-xs font-mono ${entry.href ? 'text-green-400' : 'text-gray-600'}`}>
                  {entry.href ? 'LIVE' : 'LOCKED'}
                </span>
              </div>
            )
            return entry.href ? (
              <Link key={entry.key} href={entry.href}>
                {card}
              </Link>
            ) : (
              <div key={entry.key}>{card}</div>
            )
          })}
        </div>
      </div>
    </div>
  )
}
