import Link from 'next/link'
import SignOutButton from './SignOutButton'

export default function Navbar({ username = "", coins = 0 }: { username?: string; coins?: number }) {
  return (
    <header className="flex items-center justify-between px-6 py-4 max-w-6xl mx-auto w-full">
      <Link
        href="/dashboard"
        className="font-display font-900 text-xl tracking-widest text-neon-purple neon-text"
      >
        CATSINO<span className="text-neon-cyan">.CASINO</span>
      </Link>

      <div className="flex items-center gap-3">
        <Link href="/profile" className="text-xs font-mono text-slate-400 hidden sm:block hover:text-slate-200 transition-colors">
          🐈 <span className="text-slate-200">{username}</span>
        </Link>
        <Link href="/achievements" className="text-xs text-slate-500 hidden md:block hover:text-yellow-400 transition-colors">
          🏆
        </Link>
        <Link href="/social" className="text-xs text-slate-500 hidden md:block hover:text-purple-400 transition-colors">
          👥
        </Link>
        <Link href="/companions" className="text-xs text-slate-500 hidden md:block hover:text-green-400 transition-colors">
          🐾
        </Link>
        <Link href="/quests" className="text-xs text-slate-500 hidden md:block hover:text-purple-400 transition-colors">
          📋
        </Link>
        <Link href="/events" className="text-xs text-slate-500 hidden md:block hover:text-orange-400 transition-colors">
          🎪
        </Link>
        <Link href="/tournaments" className="text-xs text-slate-500 hidden md:block hover:text-yellow-400 transition-colors">
          🏆
        </Link>
        <Link href="/leaderboard" className="text-xs text-slate-500 hidden md:block hover:text-cyan-400 transition-colors" title="Leaderboard">
          📊
        </Link>
        <Link href="/inventory" className="text-xs text-slate-500 hidden md:block hover:text-cyan-400 transition-colors">
          🎒
        </Link>
        <Link href="/districts" className="text-xs text-slate-500 hidden md:block hover:text-emerald-400 transition-colors">
          🗺️
        </Link>
        <Link href="/world-builder" className="text-xs text-slate-500 hidden md:block hover:text-purple-400 transition-colors" title="World Builder">
          🌍
        </Link>
        <div className="px-3 py-1.5 rounded-lg border border-neon-green/40 text-neon-green text-sm font-display tracking-wide">
          {coins.toLocaleString()} 🪙
        </div>
        <SignOutButton />
      </div>
    </header>
  )
}
