import { redirect } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import Navbar from '@/components/Navbar'

const MEDALS = ['🥇', '🥈', '🥉']

export default async function LeaderboardPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  const [{ data: profile }, { data: wallet }] = await Promise.all([
    supabase.from('profiles').select('username').eq('id', user.id).single(),
    supabase.from('wallets').select('coins').eq('user_id', user.id).single(),
  ])

  const username = profile?.username ?? user.email?.split('@')[0] ?? 'player'
  const coins = wallet?.coins ?? 0

  // Fetch top 50 spins by win
  const { data: topSpins } = await supabase
    .from('spins')
    .select('user_id, win, game')
    .order('win', { ascending: false })
    .limit(50)

  // Build per-user best win
  const bestByUser = new Map<string, { win: number; game: string }>()
  for (const spin of topSpins ?? []) {
    const existing = bestByUser.get(spin.user_id)
    if (!existing || spin.win > existing.win) {
      bestByUser.set(spin.user_id, { win: spin.win, game: spin.game })
    }
  }

  const userIds = Array.from(bestByUser.keys())

  // Fetch usernames for those user IDs
  const { data: profiles } = userIds.length
    ? await supabase.from('profiles').select('id, username').in('id', userIds)
    : { data: [] }

  const usernameMap = new Map<string, string>()
  for (const p of profiles ?? []) {
    usernameMap.set(p.id, p.username)
  }

  // Build sorted leaderboard (top 10)
  const leaderboard = Array.from(bestByUser.entries())
    .map(([uid, { win, game }]) => ({
      uid,
      username: usernameMap.get(uid) ?? 'Anonymous',
      best_win: win,
      game,
    }))
    .sort((a, b) => b.best_win - a.best_win)
    .slice(0, 10)
    .map((entry, i) => ({ rank: i + 1, ...entry }))

  return (
    <main className="min-h-screen">
      <Navbar username={username} coins={coins} />
      <section className="max-w-3xl mx-auto px-6 py-8">
        <Link href="/dashboard" className="text-xs text-neon-cyan hover:text-neon-purple">
          &larr; Back to lobby
        </Link>
        <h1 className="font-display text-2xl text-neon-purple neon-text tracking-widest mt-2 mb-1">
          LEADERBOARD
        </h1>
        <p className="text-xs text-slate-500 mb-8">Top single-spin wins across all games.</p>

        <div className="rounded-xl border border-neon-purple/30 bg-[#0a0813]/80 overflow-hidden">
          {leaderboard.length === 0 ? (
            <p className="text-xs text-slate-500 p-5">No spins recorded yet — be the first!</p>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="text-slate-500 border-b border-neon-purple/20 text-xs">
                  <th className="text-left p-4">Rank</th>
                  <th className="text-left p-4">Player</th>
                  <th className="text-left p-4">Game</th>
                  <th className="text-right p-4">Best Win</th>
                </tr>
              </thead>
              <tbody>
                {leaderboard.map((entry) => (
                  <tr
                    key={entry.uid}
                    className={`border-b border-neon-purple/10 last:border-0 ${
                      entry.uid === user.id ? 'bg-neon-purple/5' : ''
                    }`}
                  >
                    <td className="p-4">
                      <span className="text-lg">
                        {MEDALS[entry.rank - 1] ?? `#${entry.rank}`}
                      </span>
                    </td>
                    <td className={`p-4 font-bold ${entry.uid === user.id ? 'text-neon-cyan' : 'text-slate-200'}`}>
                      {entry.username}
                      {entry.uid === user.id && <span className="ml-2 text-xs text-slate-500">(you)</span>}
                    </td>
                    <td className="p-4 text-slate-400 text-xs">{entry.game.replace(/_/g, ' ')}</td>
                    <td className="p-4 text-right text-neon-green font-bold">
                      {entry.best_win.toLocaleString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </section>
    </main>
  )
}
