import Link from 'next/link'
import { GAMES, COLOR_CLASSES } from '@/lib/games'

export default function HomePage() {
  return (
    <main className="min-h-screen flex flex-col">
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

      <section className="flex-1 flex flex-col items-center justify-center text-center px-6 py-16">
        <div className="text-6xl mb-4 cat-eyes">🐈‍⬛⚡</div>
        <h1 className="font-display font-900 text-4xl sm:text-6xl tracking-wide text-neon-purple neon-text mb-4">
          CATSINO.CASINO
        </h1>
        <p className="max-w-xl text-slate-300 text-sm sm:text-base mb-2">
          A neon cyber-cat social casino. Free Cat Coins, no real money, no
          cash-outs &mdash; just glowing reels and nine lives of luck.
        </p>
        <p className="max-w-xl text-slate-500 text-xs mb-8">
          100% virtual currency. For entertainment only. No purchases, no
          sweepstakes, no prizes.
        </p>
        <Link
          href="/signup"
          className="px-8 py-3 rounded-lg bg-neon-purple text-white font-display tracking-widest neon-border hover:opacity-90 transition-opacity"
        >
          GET 10,000 CAT COINS
        </Link>
      </section>

      <section className="px-6 pb-16 max-w-6xl mx-auto w-full">
        <h2 className="font-display text-lg tracking-widest text-center text-neon-cyan neon-text mb-8">
          GAME LOBBY
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
          {GAMES.map((game) => {
            const c = COLOR_CLASSES[game.color]
            return (
              <div
                key={game.slug}
                className={`rounded-xl border ${c.border} bg-[#0a0813]/80 p-5 flex flex-col gap-2 ${game.playable ? c.glow : ''}`}
              >
                <div className="flex items-center justify-between">
                  <span className="text-3xl">{game.emoji}</span>
                  {game.playable ? (
                    <span className={`text-[10px] tracking-widest px-2 py-1 rounded border ${c.border} ${c.text}`}>
                      LIVE
                    </span>
                  ) : (
                    <span className="text-[10px] tracking-widest px-2 py-1 rounded border border-slate-700 text-slate-500">
                      SOON
                    </span>
                  )}
                </div>
                <h3 className={`font-display text-sm tracking-wide ${c.text}`}>{game.name}</h3>
                <p className="text-xs text-slate-400">{game.tagline}</p>
              </div>
            )
          })}
        </div>
      </section>

      <footer className="text-center text-xs text-slate-600 pb-6">
        CATSINO.CASINO &mdash; virtual coins only. No purchase necessary. Not gambling.
      </footer>
    </main>
  )
}
