import Link from 'next/link'
import NeonBackground from '@/components/NeonBackground'

// The six reality layers. This landing IS the Subliminal: the calm room
// you always start in, with a door to each layer. The casino is one
// layer of six — a feature, never the main game.
const LAYERS = [
  {
    id: 'subliminal',
    name: 'Subliminal',
    tag: 'The Apartment',
    href: '/plots',
    accent: 'text-violet-300 border-violet-400/40 hover:bg-violet-400/10',
    desc: 'Your start screen and UGC studio. Invite-only, tiered from a private studio flat to a 300-soul public pavilion. All building happens here.',
  },
  {
    id: 'hyperliminal',
    name: 'Hyperliminal',
    tag: 'The Catsino',
    href: '/games',
    accent: 'text-fuchsia-300 border-fuchsia-400/40 hover:bg-fuchsia-400/10',
    desc: 'The neon casino reality — games of chance, districts, tournaments, and the PVXC survival pit. One layer of six.',
  },
  {
    id: 'liminal',
    name: 'Liminal',
    tag: 'The Between',
    href: '/world-builder',
    accent: 'text-cyan-300 border-cyan-400/40 hover:bg-cyan-400/10',
    desc: 'The connective tissue between realities. Never static — no chunk survives your departure. Wander too long and the Periliminal notices you.',
  },
  {
    id: 'superliminal',
    name: 'Superliminal',
    tag: 'DFW Metroplex',
    href: '/districts',
    accent: 'text-amber-300 border-amber-400/40 hover:bg-amber-400/10',
    desc: 'The main MMORPG layer. Arlington neutral center; Dallas, Fort Worth and Denton faction hubs; infinite claimable wilds between.',
  },
  {
    id: 'extraliminal',
    name: 'Extraliminal',
    tag: 'The Overlay',
    href: '/events',
    accent: 'text-emerald-300 border-emerald-400/40 hover:bg-emerald-400/10',
    desc: 'The real-world overlay: roaming entities, guild halls at claimable landmarks, guild wars through liminal doors.',
  },
  {
    id: 'periliminal',
    name: 'Periliminal',
    tag: 'The Anchor',
    href: '/lore',
    accent: 'text-red-300 border-red-400/30 hover:bg-red-400/5',
    desc: 'The psychological layer. It cannot be entered — it enters you. Death loses everything. Highest risk, highest rewards.',
    locked: true,
  },
]

export default function HomePage() {
  return (
    <main className="relative min-h-screen flex flex-col overflow-hidden">
      <NeonBackground />

      <header className="flex items-center justify-between px-6 py-5 max-w-6xl mx-auto w-full">
        <div className="font-display font-900 text-2xl tracking-widest text-neon-purple neon-text">
          PERILIMINAL<span className="text-neon-cyan">.SPACE</span>
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
            Enter the Subliminal
          </Link>
        </nav>
      </header>

      <section className="px-6 pt-10 pb-6 max-w-4xl mx-auto w-full text-center">
        <h1 className="font-display text-4xl md:text-5xl tracking-widest text-white neon-text">
          SIX REALITIES. ONE OF YOU.
        </h1>
        <p className="mt-4 text-slate-400 max-w-2xl mx-auto">
          A psychology XRMMORPG where your race is the material of reality and
          your frame is how it sounds. No two players see or hear the same
          game. Every session begins in your Subliminal — the calm room with
          six doors.
        </p>
      </section>

      <section className="px-6 pb-16 max-w-6xl mx-auto w-full">
        <h2 className="font-display text-lg tracking-widest text-center text-neon-cyan neon-text mb-8">
          CHOOSE YOUR REALITY
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {LAYERS.map((l) => (
            <Link
              key={l.id}
              href={l.locked ? '#' : l.href}
              aria-disabled={l.locked}
              className={`block rounded-xl border bg-black/40 p-5 transition-colors ${l.accent} ${
                l.locked ? 'opacity-60 cursor-not-allowed' : ''
              }`}
            >
              <div className="font-display tracking-widest text-lg">
                {l.name.toUpperCase()}
              </div>
              <div className="text-xs uppercase tracking-wider opacity-70 mb-2">
                {l.tag}
                {l.locked ? ' — cannot be entered' : ''}
              </div>
              <p className="text-sm text-slate-400">{l.desc}</p>
            </Link>
          ))}
        </div>
      </section>

      <footer className="text-center text-xs text-slate-600 pb-6 px-6">
        PERILIMINAL.SPACE &mdash; the Catsino is one reality layer; virtual
        coins only, no purchase necessary, not gambling. Canon UGC &copy;{' '}
        Holloway&apos;s Own Providential Enterprise Apex Holdings Inc. —
        creators keep their blueprints, names, and sole crafting rights.
      </footer>
    </main>
  )
}
