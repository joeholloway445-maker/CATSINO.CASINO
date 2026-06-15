import Link from 'next/link'
import SignOutButton from './SignOutButton'

export default function Navbar({ username, coins }: { username: string; coins: number }) {
  return (
    <header className="flex items-center justify-between px-6 py-4 max-w-6xl mx-auto w-full">
      <Link
        href="/dashboard"
        className="font-display font-900 text-xl tracking-widest text-neon-purple neon-text"
      >
        CATSINO<span className="text-neon-cyan">.CASINO</span>
      </Link>

      <div className="flex items-center gap-4">
        <div className="text-xs font-mono text-slate-400 hidden sm:block">
          🐈 <span className="text-slate-200">{username}</span>
        </div>
        <div className="px-3 py-1.5 rounded-lg border border-neon-green/40 text-neon-green text-sm font-display tracking-wide">
          {coins.toLocaleString()} 🪙
        </div>
        <SignOutButton />
      </div>
    </header>
  )
}
