import Link from 'next/link'

export default function HomePage() {
  return (
    <main className="min-h-screen flex flex-col items-center justify-center px-6 relative overflow-hidden">
      {/* Grid background */}
      <div
        className="absolute inset-0 opacity-20"
        style={{
          backgroundImage:
            'linear-gradient(#1a1a3e 1px, transparent 1px), linear-gradient(90deg, #1a1a3e 1px, transparent 1px)',
          backgroundSize: '40px 40px',
        }}
      />

      <div className="relative z-10 text-center max-w-2xl">
        <div className="text-purple-500 text-5xl mb-6 tracking-widest font-mono">✦ HDV ✦</div>

        <h1 className="text-4xl sm:text-5xl font-mono font-bold text-slate-100 mb-3 tracking-tight">
          THE HDV CORE
        </h1>

        <p className="text-purple-400 font-mono text-sm tracking-widest mb-2">
          HOPE · DREAM · VISION
        </p>

        <p className="text-slate-400 font-mono text-sm mb-10 leading-relaxed">
          A multi-mode experience across three realms.<br />
          Your HOPE companion travels with you always.
        </p>

        <Link
          href="/game"
          className="inline-block px-10 py-4 bg-purple-700 hover:bg-purple-600 text-white font-mono text-lg tracking-widest rounded-lg border border-purple-500 transition-colors shadow-lg shadow-purple-950/60"
        >
          ENTER THE CORE
        </Link>

        <div className="mt-4 flex items-center justify-center gap-3">
          <Link
            href="/cleaner"
            className="inline-block px-6 py-2 text-purple-400 hover:text-purple-300 font-mono text-xs tracking-widest border border-purple-900 rounded-lg transition-colors"
          >
            HOPE CLEANER →
          </Link>
          <Link
            href="/studio"
            className="inline-block px-6 py-2 text-fuchsia-400 hover:text-fuchsia-300 font-mono text-xs tracking-widest border border-fuchsia-900 rounded-lg transition-colors"
          >
            DREAM STUDIO →
          </Link>
          <Link
            href="/builder"
            className="inline-block px-6 py-2 text-cyan-400 hover:text-cyan-300 font-mono text-xs tracking-widest border border-cyan-900 rounded-lg transition-colors"
          >
            BUILDER →
          </Link>
        </div>

        <div className="mt-14 grid grid-cols-3 gap-4 text-left">
          {[
            { title: 'CHRONICLES', sub: 'RPG', borderColor: 'border-green-700', textColor: 'text-green-400', desc: 'Story-driven exploration in the HOPE authority layer.' },
            { title: 'FRACTURE', sub: 'ACTION', borderColor: 'border-red-700', textColor: 'text-red-400', desc: 'Fast-paced combat across shattered zones.' },
            { title: 'DOMINION', sub: 'SIM', borderColor: 'border-blue-700', textColor: 'text-blue-400', desc: 'Build and manage your empire with HOPE guidance.' },
          ].map(({ title, sub, borderColor, textColor, desc }) => (
            <div
              key={title}
              className={`rounded-lg border bg-[#1a1a2e]/50 p-4 ${borderColor}`}
            >
              <div className={`font-mono text-xs mb-1 ${textColor}`}>{sub}</div>
              <div className="font-mono text-sm text-slate-200 mb-2">{title}</div>
              <div className="font-mono text-xs text-slate-500 leading-relaxed">{desc}</div>
            </div>
          ))}
        </div>
      </div>
    </main>
  )
}
