import { redirect } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import Navbar from '@/components/Navbar'

const ACHIEVEMENTS = [
  { id: "first_win", name: "First Blood", desc: "Win your first game", icon: "🏆", xp: 50, category: "games" },
  { id: "high_roller", name: "High Roller", desc: "Place a bet of 1,000 coins", icon: "💰", xp: 100, category: "economy" },
  { id: "jackpot", name: "Jackpot!", desc: "Hit a 25x multiplier or higher", icon: "🎰", xp: 500, category: "games" },
  { id: "streak_3", name: "Hot Streak", desc: "Win 3 games in a row", icon: "🔥", xp: 150, category: "games" },
  { id: "streak_7", name: "Seven Lives", desc: "Win 7 games in a row", icon: "⭐", xp: 500, category: "games" },
  { id: "daily_7", name: "Creature of Habit", desc: "Claim daily bonus 7 days straight", icon: "📅", xp: 250, category: "economy" },
  { id: "daily_30", name: "Devoted", desc: "Claim daily bonus 30 days in a row", icon: "🌙", xp: 1000, category: "economy" },
  { id: "coins_1000", name: "Coin Collector", desc: "Accumulate 1,000 coins", icon: "🪙", xp: 50, category: "economy" },
  { id: "coins_10000", name: "Wealthy Cat", desc: "Accumulate 10,000 coins", icon: "💎", xp: 200, category: "economy" },
  { id: "coins_100000", name: "Fat Cat", desc: "Accumulate 100,000 coins", icon: "👑", xp: 1000, category: "economy" },
  { id: "scratch_big", name: "Lucky Scratch", desc: "Win 500+ coins from Catnip Cash", icon: "🌿", xp: 200, category: "games" },
  { id: "slots_crown", name: "Crown Chaser", desc: "Land CROWN on all 3 slot reels", icon: "👑", xp: 500, category: "games" },
]

const CATEGORY_COLORS: Record<string, string> = {
  games: "text-neon-cyan border-neon-cyan/30",
  economy: "text-yellow-400 border-yellow-400/30",
  companions: "text-neon-purple border-neon-purple/30",
  racing: "text-orange-400 border-orange-400/30",
  social: "text-neon-pink border-neon-pink/30",
}

export default async function AchievementsPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const [{ data: profile }, { data: wallet }] = await Promise.all([
    supabase.from('profiles').select('username').eq('id', user.id).single(),
    supabase.from('wallets').select('coins, xp').eq('user_id', user.id).single(),
  ])

  const username = profile?.username ?? user.email?.split('@')[0] ?? 'player'
  const coins = wallet?.coins ?? 0
  const xp = wallet?.xp ?? 0

  // Derive unlocked achievements from game data (simplified server-side checks)
  const { data: spins } = await supabase
    .from('spins').select('game, bet, win, multiplier').eq('user_id', user.id)

  const unlocked = new Set<string>()
  if (spins) {
    if (spins.some(s => s.win > 0)) unlocked.add('first_win')
    if (spins.some(s => s.bet >= 1000)) unlocked.add('high_roller')
    if (spins.some(s => s.multiplier >= 25)) unlocked.add('jackpot')
    if (spins.some(s => s.win >= 500 && s.game === 'catnip-cash')) unlocked.add('scratch_big')
  }
  if (coins >= 1000) unlocked.add('coins_1000')
  if (coins >= 10000) unlocked.add('coins_10000')
  if (coins >= 100000) unlocked.add('coins_100000')

  const unlockedCount = unlocked.size

  return (
    <main className="min-h-screen">
      <Navbar username={username} coins={coins} />
      <section className="max-w-4xl mx-auto px-6 py-8">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="font-display text-2xl text-neon-purple neon-text tracking-widest">🏆 ACHIEVEMENTS</h1>
            <p className="text-xs text-slate-500 mt-1">{unlockedCount} / {ACHIEVEMENTS.length} unlocked &mdash; XP: {xp.toLocaleString()}</p>
          </div>
          <Link href="/profile" className="text-xs font-display tracking-widest text-slate-500 border border-slate-700 px-3 py-1.5 rounded-lg hover:border-slate-500 transition-all">
            ← Profile
          </Link>
        </div>

        {/* Progress bar */}
        <div className="mb-8">
          <div className="h-2 rounded-full bg-slate-800 overflow-hidden">
            <div className="h-full rounded-full bg-gradient-to-r from-neon-purple to-neon-cyan transition-all"
              style={{ width: `${Math.round((unlockedCount / ACHIEVEMENTS.length) * 100)}%` }} />
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          {ACHIEVEMENTS.map(a => {
            const done = unlocked.has(a.id)
            const colorClass = CATEGORY_COLORS[a.category] ?? 'text-slate-400 border-slate-700'
            return (
              <div key={a.id}
                className={`rounded-xl border p-4 flex items-center gap-4 transition-all ${done ? colorClass + ' bg-[#0a0813]/80' : 'border-slate-800 bg-[#0a0813]/40'}`}>
                <span className={`text-3xl ${done ? '' : 'grayscale opacity-30'}`}>{a.icon}</span>
                <div className="flex-1 min-w-0">
                  <p className={`font-display text-sm tracking-wider ${done ? '' : 'text-slate-600'}`}>{a.name}</p>
                  <p className="text-xs text-slate-500 truncate">{a.desc}</p>
                </div>
                <span className={`text-xs font-bold flex-shrink-0 ${done ? 'text-neon-green' : 'text-slate-700'}`}>
                  +{a.xp} XP
                </span>
              </div>
            )
          })}
        </div>
      </section>
    </main>
  )
}
