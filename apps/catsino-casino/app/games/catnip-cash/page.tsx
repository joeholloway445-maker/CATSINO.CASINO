import { redirect } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/server'
import Navbar from '@/components/Navbar'
import ScratchCard from './ScratchCard'

export default async function CatnipCashPage() {
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
        <h1 className="font-display text-2xl text-neon-green neon-text tracking-widest mt-2 mb-1">
          CATNIP CASH
        </h1>
        <p className="text-xs text-slate-500 mb-8">
          Match 3+ symbols on your scratch card for big wins — 9 of a kind pays 100x!
        </p>

        <ScratchCard initialBalance={coins} />
      </section>
    </main>
  )
}
