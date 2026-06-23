'use client'

import Link from 'next/link'
import { motion } from 'framer-motion'
import { GAMES, COLOR_CLASSES, type GameDef } from '@/lib/games'

const container = {
  hidden: {},
  show: {
    transition: { staggerChildren: 0.06 },
  },
}

const item = {
  hidden: { opacity: 0, y: 16, scale: 0.96 },
  show: { opacity: 1, y: 0, scale: 1 },
}

function Card({ game }: { game: GameDef }) {
  const c = COLOR_CLASSES[game.color]
  return (
    <motion.div
      variants={item}
      whileHover={game.playable ? { y: -4, scale: 1.03 } : {}}
      transition={{ duration: 0.25, ease: 'easeOut' }}
      className={`rounded-xl border ${c.border} bg-[#0a0813]/80 p-5 flex flex-col gap-2 h-full ${
        game.playable ? `${c.glow} cursor-pointer` : 'opacity-60'
      }`}
    >
      <div className="flex items-center justify-between">
        <motion.span
          className="text-3xl"
          animate={game.playable ? { scale: [1, 1.08, 1] } : {}}
          transition={game.playable ? { repeat: Infinity, duration: 2.4, ease: 'easeInOut' } : {}}
        >
          {game.emoji}
        </motion.span>
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
    </motion.div>
  )
}

export default function LobbyGrid({ linkPlayable = false }: { linkPlayable?: boolean }) {
  return (
    <motion.div
      variants={container}
      initial="hidden"
      animate="show"
      className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4"
    >
      {GAMES.map((game) =>
        linkPlayable && game.playable ? (
          <Link key={game.slug} href={`/games/${game.slug}`}>
            <Card game={game} />
          </Link>
        ) : (
          <Card key={game.slug} game={game} />
        ),
      )}
    </motion.div>
  )
}
