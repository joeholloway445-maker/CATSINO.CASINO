import { redirect } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import Navbar from '@/components/Navbar'
import ShopClient from './ShopClient'

export default async function ShopPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) redirect('/login')

  const [{ data: profile }, { data: wallet }] = await Promise.all([
    supabase.from('profiles').select('username').eq('id', user.id).single(),
    supabase.from('wallets').select('coins, xp').eq('user_id', user.id).single(),
  ])

  const username = profile?.username ?? user.email?.split('@')[0] ?? 'player'
  const coins = wallet?.coins ?? 0

  return (
    <main className="min-h-screen">
      <Navbar username={username} coins={coins} />
      <section className="max-w-4xl mx-auto px-6 py-8">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="font-display text-2xl text-neon-pink neon-text tracking-widest">🛒 CAT SHOP</h1>
            <p className="text-xs text-slate-500 mt-1">Daily stock refreshes every 24 hours</p>
          </div>
          <Link href="/dashboard" className="text-xs font-display tracking-widest text-slate-500 border border-slate-700 px-3 py-1.5 rounded-lg hover:border-slate-500 transition-all">
            ← Lobby
          </Link>
        </div>
        <ShopClient initialCoins={coins} userId={user.id} />
      </section>
    </main>
  )
}
