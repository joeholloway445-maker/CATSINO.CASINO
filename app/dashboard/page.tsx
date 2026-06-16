import { redirect } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import Navbar from '@/components/Navbar'
import DailyBonusButton from '@/components/DailyBonusButton'
import LobbyGrid from '@/components/LobbyGrid'

function isDailyBonusAvailable(lastClaim: string | null): boolean {
  if (!lastClaim) return true
  return Date.now() - new Date(lastClaim).getTime() > 20 * 60 * 60 * 1000
}

export default async function DashboardPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  const [{ data: profile }, { data: wallet }, { data: spins }] = await Promise.all([
    supabase.from('profiles').select('username').eq('id', user.id).single(),
    supabase.from('wallets').select('coins, xp, daily_streak, last_daily_claim').eq('user_id', user.id).single(),
    supabase
      .from('spins')
      .select('game, bet, win, multiplier, reels, created_at')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })
      .limit(10),
  ])

  const username = profile?.username ?? user.email?.split('@')[0] ?? 'player'
  const coins = wallet?.coins ?? 0
  const xp = wallet?.xp ?? 0
  const streak = wallet?.daily_streak ?? 0
  const canClaim = isDailyBonusAvailable(wallet?.last_daily_claim ?? null)

  return (
    <main className="min-h-screen">
      <Navbar username={username} coins={coins} />

      <section className="max-w-6xl mx-auto px-6 py-8">
        <h1 className="font-display text-2xl text-neon-purple neon-text tracking-widest mb-1">
          WELCOME BACK, {username.toUpperCase()}
        </h1>
        <p className="text-xs text-slate-500 mb-8">XP: {xp.toLocaleString()} &mdash; Daily streak: {streak} 🔥</p>

        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4 mb-10">
          <DailyBonusButton canClaim={canClaim} />
        </div>

        <h2 className="font-display text-lg tracking-widest text-neon-cyan neon-text mb-4">GAME LOBBY</h2>
        <div className="mb-6">
          <LobbyGrid linkPlayable />
        </div>

        <div className="mb-10 flex gap-3 flex-wrap">
          <Link
            href="/leaderboard"
            className="inline-block px-6 py-2.5 rounded-xl border border-neon-purple/50 text-neon-purple text-xs font-display tracking-widest hover:bg-neon-purple/10 hover:shadow-[0_0_16px_rgba(176,38,255,0.3)] transition-all"
          >
            🏆 LEADERBOARD
          </Link>
          <Link
            href="/shop"
            className="inline-block px-6 py-2.5 rounded-xl border border-neon-pink/50 text-neon-pink text-xs font-display tracking-widest hover:bg-neon-pink/10 hover:shadow-[0_0_16px_rgba(255,43,214,0.3)] transition-all"
          >
            🛒 SHOP
          </Link>
          <Link
            href="/achievements"
            className="inline-block px-6 py-2.5 rounded-xl border border-yellow-500/50 text-yellow-400 text-xs font-display tracking-widest hover:bg-yellow-500/10 hover:shadow-[0_0_16px_rgba(234,179,8,0.3)] transition-all"
          >
            🏅 ACHIEVEMENTS
          </Link>
          <Link
            href="/profile"
            className="inline-block px-6 py-2.5 rounded-xl border border-neon-cyan/50 text-neon-cyan text-xs font-display tracking-widest hover:bg-neon-cyan/10 hover:shadow-[0_0_16px_rgba(0,246,255,0.3)] transition-all"
          >
            🐱 PROFILE
          </Link>
          <Link
            href="/social"
            className="inline-block px-6 py-2.5 rounded-xl border border-purple-500/50 text-purple-400 text-xs font-display tracking-widest hover:bg-purple-500/10 hover:shadow-[0_0_16px_rgba(168,85,247,0.3)] transition-all"
          >
            👥 SOCIAL
          </Link>
          <Link
            href="/battlepass"
            className="inline-block px-6 py-2.5 rounded-xl border border-yellow-500/50 text-yellow-300 text-xs font-display tracking-widest hover:bg-yellow-500/10 hover:shadow-[0_0_16px_rgba(234,179,8,0.3)] transition-all"
          >
            ⚡ BATTLE PASS
          </Link>
        </div>

        <h2 className="font-display text-lg tracking-widest text-neon-pink neon-text mb-4">RECENT SPINS</h2>
        <div className="rounded-xl border border-neon-pink/30 bg-[#0a0813]/80 overflow-hidden">
          {!spins || spins.length === 0 ? (
            <p className="text-xs text-slate-500 p-5">No spins yet &mdash; head to the lobby and give the reels a pull!</p>
          ) : (
            <table className="w-full text-xs">
              <thead>
                <tr className="text-slate-500 border-b border-neon-pink/20">
                  <th className="text-left p-3">Game</th>
                  <th className="text-left p-3">Reels</th>
                  <th className="text-right p-3">Bet</th>
                  <th className="text-right p-3">Win</th>
                  <th className="text-right p-3">When</th>
                </tr>
              </thead>
              <tbody>
                {spins.map((spin, i) => (
                  <tr key={i} className="border-b border-neon-pink/10 last:border-0">
                    <td className="p-3 text-slate-300">{spin.game}</td>
                    <td className="p-3 text-slate-400">{(spin.reels as string[]).join(' ')}</td>
                    <td className="p-3 text-right text-slate-400">{spin.bet.toLocaleString()}</td>
                    <td className={`p-3 text-right ${spin.win > 0 ? 'text-neon-green' : 'text-slate-500'}`}>
                      {spin.win.toLocaleString()}
                    </td>
                    <td className="p-3 text-right text-slate-500">
                      {new Date(spin.created_at).toLocaleString()}
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
