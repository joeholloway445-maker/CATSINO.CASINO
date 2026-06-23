import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import Navbar from '@/components/Navbar'
import PokerGame from './PokerGame'

export default async function WhiskerWinsPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()

  if (!user) redirect('/login')

  const [{ data: profile }, { data: wallet }] = await Promise.all([
    supabase.from('profiles').select('username').eq('id', user.id).single(),
    supabase.from('wallets').select('coins').eq('user_id', user.id).single(),
  ])

  const username = profile?.username ?? user.email?.split('@')[0] ?? 'player'
  const coins = wallet?.coins ?? 0

  return (
    <main className="min-h-screen">
      <Navbar username={username} coins={coins} />
      <section className="max-w-4xl mx-auto px-6 py-8">
        <h1 className="font-display text-2xl text-neon-cyan neon-text tracking-widest mb-2">
          🎴 WHISKER WINS
        </h1>
        <p className="text-xs text-slate-500 mb-8">5-card draw poker — Jacks or Better</p>
        <PokerGame initialBalance={coins} />
      </section>
    </main>
  )
}
