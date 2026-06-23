import Link from 'next/link'

export default function ProfilePage() {
  return (
    <main className="min-h-screen px-6 py-10 max-w-3xl mx-auto">
      <div className="flex items-center gap-4 mb-10">
        <Link
          href="/"
          className="font-mono text-xs text-purple-500 hover:text-purple-300 transition-colors"
        >
          ← HOME
        </Link>
        <h1 className="font-mono text-xl text-slate-200 tracking-widest">PLAYER PROFILE</h1>
      </div>

      {/* Player card */}
      <div className="rounded-xl border border-purple-800 bg-[#1a1a2e]/60 p-6 mb-6">
        <div className="flex items-center gap-4 mb-6">
          <div className="w-16 h-16 rounded-full bg-purple-900 border-2 border-purple-500 flex items-center justify-center text-2xl">
            ✦
          </div>
          <div>
            <div className="font-mono text-slate-200 text-lg">Player</div>
            <div className="font-mono text-purple-500 text-xs tracking-widest">HOPE BONDED · LVL 1</div>
          </div>
        </div>

        <div className="grid grid-cols-3 gap-4">
          {[
            { label: 'LEVEL', value: '1' },
            { label: 'XP', value: '0' },
            { label: 'REALM', value: '—' },
          ].map(({ label, value }) => (
            <div key={label} className="rounded-lg bg-[#0f0f1a] border border-purple-900 p-3 text-center">
              <div className="font-mono text-xs text-purple-600 mb-1">{label}</div>
              <div className="font-mono text-slate-200 text-xl">{value}</div>
            </div>
          ))}
        </div>
      </div>

      {/* HOPE companion status */}
      <div className="rounded-xl border border-purple-800 bg-[#1a1a2e]/60 p-6">
        <div className="flex items-center gap-2 mb-4">
          <span className="text-purple-400">✦</span>
          <h2 className="font-mono text-sm text-purple-300 tracking-widest">HOPE COMPANION</h2>
          <span className="ml-auto text-xs font-mono text-green-500">● ACTIVE</span>
        </div>
        <p className="font-mono text-xs text-slate-400 leading-relaxed">
          Your HOPE instance is initialized and ready. As you progress through each realm,
          HOPE will learn your playstyle and provide personalized guidance. Full AI
          capabilities unlock in a future update.
        </p>
      </div>

      <div className="mt-8 flex gap-4 flex-wrap">
        <Link
          href="/character-select"
          className="flex-1 text-center py-3 rounded-lg bg-purple-700 hover:bg-purple-600 font-mono text-sm text-white tracking-widest transition-colors border border-purple-500"
        >
          PLAY
        </Link>
        <Link
          href="/omnidex"
          className="flex-1 text-center py-3 rounded-lg border border-purple-700 font-mono text-sm text-purple-300 hover:bg-purple-900/40 tracking-widest transition-colors"
        >
          OMNIDEX
        </Link>
        <Link
          href="/creations"
          className="flex-1 text-center py-3 rounded-lg border border-purple-700 font-mono text-sm text-purple-300 hover:bg-purple-900/40 tracking-widest transition-colors"
        >
          BLUEPRINT WORKSHOP
        </Link>
      </div>
    </main>
  )
}
