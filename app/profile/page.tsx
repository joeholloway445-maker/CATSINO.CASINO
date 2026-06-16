import { redirect } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import Navbar from '@/components/Navbar'

function xpToLevel(xp: number): { level: number; progress: number; needed: number } {
  let level = 1
  let total = 0
  while (true) {
    const needed = level * 500
    if (total + needed > xp) {
      return { level, progress: xp - total, needed }
    }
    total += needed
    level++
  }
}

export default async function ProfilePage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const [{ data: profile }, { data: wallet }, { data: spins }] = await Promise.all([
    supabase.from('profiles').select('username').eq('id', user.id).single(),
    supabase.from('wallets').select('coins, xp, daily_streak, last_daily_claim').eq('user_id', user.id).single(),
    supabase.from('spins').select('game, bet, win, multiplier, created_at').eq('user_id', user.id).order('created_at', { ascending: false }).limit(50),
  ])

  const username = profile?.username ?? user.email?.split('@')[0] ?? 'player'
  const coins = wallet?.coins ?? 0
  const xp = wallet?.xp ?? 0
  const streak = wallet?.daily_streak ?? 0

  const { level, progress, needed } = xpToLevel(xp)
  const pct = Math.round((progress / needed) * 100)

  // Compute stats from spins
  const totalSpins = spins?.length ?? 0
  const totalWagered = spins?.reduce((s, r) => s + r.bet, 0) ?? 0
  const totalWon = spins?.reduce((s, r) => s + r.win, 0) ?? 0
  const biggestWin = spins?.reduce((max, r) => Math.max(max, r.win), 0) ?? 0
  const winRate = totalSpins > 0 ? Math.round((spins!.filter(r => r.win > 0).length / totalSpins) * 100) : 0

  const byGame: Record<string, { spins: number; won: number; wagered: number }> = {}
  for (const s of spins ?? []) {
    if (!byGame[s.game]) byGame[s.game] = { spins: 0, won: 0, wagered: 0 }
    byGame[s.game].spins++
    byGame[s.game].won += s.win
    byGame[s.game].wagered += s.bet
  }

  return (
    <main className="min-h-screen">
      <Navbar username={username} coins={coins} />
      <section className="max-w-4xl mx-auto px-6 py-8 space-y-8">

        {/* Profile header */}
        <div className="rounded-2xl border border-neon-purple/30 bg-[#0a0813]/80 p-6">
          <div className="flex items-center gap-6">
            <div className="w-20 h-20 rounded-full border-2 border-neon-purple flex items-center justify-center text-4xl bg-[#150d2e]">
              🐱
            </div>
            <div className="flex-1">
              <h1 className="font-display text-2xl text-neon-purple neon-text tracking-widest">{username.toUpperCase()}</h1>
              <p className="text-xs text-slate-500 mt-1">Level {level} &mdash; {xp.toLocaleString()} XP &mdash; {streak} 🔥 streak</p>
              <div className="mt-3">
                <div className="flex justify-between text-xs text-slate-500 mb-1">
                  <span>Level {level}</span>
                  <span>{progress.toLocaleString()} / {needed.toLocaleString()} XP</span>
                  <span>Level {level + 1}</span>
                </div>
                <div className="h-2 rounded-full bg-slate-800 overflow-hidden">
                  <div className="h-full rounded-full bg-gradient-to-r from-neon-purple to-neon-cyan transition-all"
                    style={{ width: `${pct}%` }} />
                </div>
              </div>
            </div>
            <div className="text-right">
              <p className="text-2xl font-bold text-neon-green">{coins.toLocaleString()}</p>
              <p className="text-xs text-slate-500">🪙 Cat Coins</p>
            </div>
          </div>
        </div>

        {/* Stats grid */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
          {[
            { label: 'Total Spins', value: totalSpins.toLocaleString(), color: 'text-neon-cyan' },
            { label: 'Win Rate', value: `${winRate}%`, color: 'text-neon-green' },
            { label: 'Total Wagered', value: totalWagered.toLocaleString(), color: 'text-neon-purple' },
            { label: 'Biggest Win', value: biggestWin.toLocaleString(), color: 'text-neon-pink' },
          ].map(s => (
            <div key={s.label} className="rounded-xl border border-slate-800 bg-[#0a0813]/60 p-4 text-center">
              <p className={`text-xl font-bold ${s.color}`}>{s.value}</p>
              <p className="text-xs text-slate-500 mt-1">{s.label}</p>
            </div>
          ))}
        </div>

        {/* Game breakdown */}
        <div>
          <h2 className="font-display text-sm tracking-widest text-neon-cyan mb-3">GAME BREAKDOWN</h2>
          <div className="rounded-xl border border-neon-cyan/20 bg-[#0a0813]/60 overflow-hidden">
            {Object.keys(byGame).length === 0 ? (
              <p className="text-xs text-slate-500 p-5">No games played yet.</p>
            ) : (
              <table className="w-full text-xs">
                <thead>
                  <tr className="text-slate-500 border-b border-neon-cyan/20">
                    <th className="text-left p-3">Game</th>
                    <th className="text-right p-3">Spins</th>
                    <th className="text-right p-3">Wagered</th>
                    <th className="text-right p-3">Won</th>
                    <th className="text-right p-3">Net</th>
                  </tr>
                </thead>
                <tbody>
                  {Object.entries(byGame).map(([game, stats]) => {
                    const net = stats.won - stats.wagered
                    return (
                      <tr key={game} className="border-b border-neon-cyan/10 last:border-0">
                        <td className="p-3 text-slate-300 capitalize">{game.replace(/-/g, ' ')}</td>
                        <td className="p-3 text-right text-slate-400">{stats.spins}</td>
                        <td className="p-3 text-right text-slate-400">{stats.wagered.toLocaleString()}</td>
                        <td className="p-3 text-right text-neon-green">{stats.won.toLocaleString()}</td>
                        <td className={`p-3 text-right font-bold ${net >= 0 ? 'text-neon-green' : 'text-red-400'}`}>
                          {net >= 0 ? '+' : ''}{net.toLocaleString()}
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            )}
          </div>
        </div>

        {/* Nav links */}
        <div className="flex gap-3 flex-wrap">
          <Link href="/dashboard" className="text-xs font-display tracking-widest text-neon-purple border border-neon-purple/40 px-4 py-2 rounded-lg hover:bg-neon-purple/10 transition-all">
            🎮 LOBBY
          </Link>
          <Link href="/leaderboard" className="text-xs font-display tracking-widest text-neon-cyan border border-neon-cyan/40 px-4 py-2 rounded-lg hover:bg-neon-cyan/10 transition-all">
            🏆 LEADERBOARD
          </Link>
        </div>
      </section>
    </main>
  )
}
