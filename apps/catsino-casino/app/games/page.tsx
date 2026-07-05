import Link from 'next/link'
import LobbyGrid from '@/components/LobbyGrid'
import NeonBackground from '@/components/NeonBackground'

export default function GamesPage() {
  return (
    <main className="relative min-h-screen flex flex-col overflow-hidden">
      <NeonBackground />

      <header className="flex items-center justify-between px-6 py-5 max-w-6xl mx-auto w-full">
        <Link
          href="/"
          className="text-sm text-slate-400 hover:text-neon-cyan transition-colors"
        >
          &larr; Back to the Subliminal
        </Link>
        <div className="font-display font-900 text-xl tracking-widest text-neon-purple neon-text">
          HYPERLIMINAL<span className="text-neon-cyan">.CATSINO</span>
        </div>
      </header>

      <section className="px-6 pt-6 pb-8 max-w-4xl mx-auto w-full text-center">
        <h1 className="font-display text-3xl md:text-4xl tracking-widest text-white neon-text">
          THE CATSINO
        </h1>
        <p className="mt-3 text-slate-400 max-w-2xl mx-auto">
          Free Cat Chips, no real money, no cash-outs — just glowing reels
          and nine lives of luck. One reality layer of six.
        </p>
      </section>

      <section className="px-6 pb-16 max-w-6xl mx-auto w-full flex-1">
        <LobbyGrid linkPlayable />
      </section>

      <footer className="text-center text-xs text-slate-600 pb-6 px-6">
        Virtual coins only. No purchase necessary. Not gambling.
      </footer>
    </main>
  )
}
