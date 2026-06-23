import { redirect } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import Navbar from '@/components/Navbar'
import WheelGame from './WheelGame'

export default async function LuckyCatJackpotPage() {
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

  return (
    <main className="min-h-screen">
      <Navbar username={username} coins={coins} />
      <section className="max-w-2xl mx-auto px-6 py-8">
        <Link href="/dashboard" className="text-xs text-neon-cyan hover:text-neon-purple">
          &larr; Back to lobby
        </Link>
        <h1 className="font-display text-2xl text-neon-pink neon-text tracking-widest mt-2 mb-1">
          LUCKY CAT JACKPOT
        </h1>
        <p className="text-xs text-slate-500 mb-8">
          Spin the wheel — land on 💎 for the 25x jackpot!
        </p>

        <WheelGame initialBalance={coins} />
      </section>
    </main>
  )
}
