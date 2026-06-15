import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import Navbar from '@/components/Navbar'
import AdjustCoinsForm from '@/components/AdjustCoinsForm'

export default async function AdminPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  const { data: profile } = await supabase.from('profiles').select('username, is_admin').eq('id', user.id).single()

  if (!profile?.is_admin) {
    redirect('/dashboard')
  }

  const { data: wallet } = await supabase.from('wallets').select('coins').eq('user_id', user.id).single()

  const { data: profiles } = await supabase
    .from('profiles')
    .select('id, username, created_at')
    .order('created_at', { ascending: false })

  const { data: wallets } = await supabase.from('wallets').select('user_id, coins, xp, daily_streak')

  const walletByUser = new Map((wallets ?? []).map((w) => [w.user_id, w]))

  return (
    <main className="min-h-screen">
      <Navbar username={profile.username} coins={wallet?.coins ?? 0} />
      <section className="max-w-4xl mx-auto px-6 py-8">
        <h1 className="font-display text-2xl text-neon-pink neon-text tracking-widest mb-1">ADMIN PANEL</h1>
        <p className="text-xs text-slate-500 mb-8">Manage users and adjust Cat Coin balances.</p>

        <div className="rounded-xl border border-neon-pink/30 bg-[#0a0813]/80 overflow-hidden">
          <table className="w-full text-xs">
            <thead>
              <tr className="text-slate-500 border-b border-neon-pink/20">
                <th className="text-left p-3">Username</th>
                <th className="text-right p-3">Coins</th>
                <th className="text-right p-3">XP</th>
                <th className="text-right p-3">Streak</th>
                <th className="text-right p-3">Joined</th>
                <th className="text-right p-3">Adjust</th>
              </tr>
            </thead>
            <tbody>
              {(profiles ?? []).map((p) => {
                const w = walletByUser.get(p.id)
                return (
                  <tr key={p.id} className="border-b border-neon-pink/10 last:border-0">
                    <td className="p-3 text-slate-300">{p.username}</td>
                    <td className="p-3 text-right text-neon-green">{(w?.coins ?? 0).toLocaleString()}</td>
                    <td className="p-3 text-right text-slate-400">{(w?.xp ?? 0).toLocaleString()}</td>
                    <td className="p-3 text-right text-slate-400">{w?.daily_streak ?? 0}</td>
                    <td className="p-3 text-right text-slate-500">{new Date(p.created_at).toLocaleDateString()}</td>
                    <td className="p-3 text-right">
                      <AdjustCoinsForm userId={p.id} />
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </section>
    </main>
  )
}
