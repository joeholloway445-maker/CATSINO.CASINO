import Link from 'next/link'
import LobbyGrid from '@/components/LobbyGrid'
import NeonBackground from '@/components/NeonBackground'
import HeroContent from '@/components/HeroContent'

export default function HomePage() {
  return (
    <main className="relative min-h-screen flex flex-col overflow-hidden">
      <NeonBackground />

      <header className="flex items-center justify-between px-6 py-5 max-w-6xl mx-auto w-full">
        <div className="font-display font-900 text-2xl tracking-widest text-neon-purple neon-text">
          CATSINO<span className="text-neon-cyan">.CASINO</span>
        </div>
        <nav className="flex gap-3">
          <Link
            href="/login"
            className="px-4 py-2 rounded-lg border border-neon-cyan/40 text-neon-cyan text-sm tracking-wide hover:bg-neon-cyan/10 transition-colors"
          >
            Sign In
          </Link>
          <Link
            href="/signup"
            className="px-4 py-2 rounded-lg bg-neon-purple text-white text-sm tracking-wide neon-border hover:opacity-90 transition-opacity"
          >
            Play Free
          </Link>
        </nav>
      </header>

      <HeroContent />

      <section className="px-6 pb-16 max-w-6xl mx-auto w-full">
        <h2 className="font-display text-lg tracking-widest text-center text-neon-cyan neon-text mb-8">
          GAME LOBBY
        </h2>
        <LobbyGrid />
      </section>

      <footer className="text-center text-xs text-slate-600 pb-6">
        CATSINO.CASINO &mdash; virtual coins only. No purchase necessary. Not gambling.
      </footer>
    </main>
  )
}
