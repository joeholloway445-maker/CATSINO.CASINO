'use client'
import Link from 'next/link'

const SECTIONS = [
  {
    href: '/world-builder/districts',
    emoji: '🗺️',
    title: 'Districts',
    desc: 'Edit the 5 districts — names, descriptions, colors, player limits, weather.',
    color: 'from-purple-600 to-purple-800',
  },
  {
    href: '/world-builder/npcs',
    emoji: '🐱',
    title: 'NPCs',
    desc: 'Add or edit characters in each district — their role, faction, greeting, and shop.',
    color: 'from-blue-600 to-blue-800',
  },
  {
    href: '/world-builder/dialogue',
    emoji: '💬',
    title: 'Dialogue',
    desc: 'Write NPC conversations with branching choices, quest triggers, and shop links.',
    color: 'from-cyan-600 to-cyan-800',
  },
  {
    href: '/world-builder/quests',
    emoji: '📋',
    title: 'Quests',
    desc: 'Create quests with objectives, rewards, and story chains — no code needed.',
    color: 'from-green-600 to-green-800',
  },
  {
    href: '/world-builder/shops',
    emoji: '🛍️',
    title: 'Shops',
    desc: 'Manage shop inventories — add items, set Cat Chip prices, assign to NPCs.',
    color: 'from-yellow-600 to-yellow-800',
  },
]

export default function WorldBuilderPage() {
  return (
    <main className="min-h-screen bg-gray-950 text-white p-8">
      <div className="max-w-5xl mx-auto">
        <div className="mb-10 text-center">
          <h1 className="text-4xl font-bold mb-3">🌍 World Builder</h1>
          <p className="text-gray-400 text-lg max-w-2xl mx-auto">
            Build and customize the CATSINO.CASINO world — no coding or game design experience needed.
            Every change saves instantly and applies next time the game loads.
          </p>
          <div className="mt-4 inline-block bg-yellow-900/40 border border-yellow-600 rounded-lg px-4 py-2 text-yellow-300 text-sm">
            💡 Tip: Start with <strong>Districts</strong>, then add <strong>NPCs</strong>, write their <strong>Dialogue</strong>, and set up <strong>Quests</strong>.
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {SECTIONS.map((s) => (
            <Link key={s.href} href={s.href} className="group block">
              <div className={`bg-gradient-to-br ${s.color} rounded-2xl p-6 h-full hover:scale-[1.02] transition-transform duration-200 shadow-lg`}>
                <div className="text-5xl mb-3">{s.emoji}</div>
                <h2 className="text-xl font-bold mb-2">{s.title}</h2>
                <p className="text-white/80 text-sm leading-relaxed">{s.desc}</p>
                <div className="mt-4 text-white/60 text-xs group-hover:text-white transition-colors">
                  Open {s.title} Editor →
                </div>
              </div>
            </Link>
          ))}
        </div>

        <div className="mt-10 bg-gray-900 rounded-2xl p-6 border border-gray-800">
          <h3 className="text-lg font-semibold mb-3">📖 How It Works</h3>
          <ol className="space-y-2 text-gray-400 text-sm list-decimal list-inside">
            <li>Use the editors above to customize any part of the world.</li>
            <li>Changes save to the database immediately.</li>
            <li>The Godot game also reads <code className="bg-gray-800 px-1 rounded">godot/world_data/*.json</code> files — edit those for offline changes.</li>
            <li>Restart the Godot project to see your changes reflected in-game.</li>
            <li>All economy uses virtual Cat Chips — no real money involved.</li>
          </ol>
        </div>

        <div className="mt-4 text-center">
          <Link href="/dashboard" className="text-gray-500 hover:text-gray-300 text-sm transition-colors">
            ← Back to Dashboard
          </Link>
        </div>
      </div>
    </main>
  )
}
