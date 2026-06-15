'use client'

import Link from 'next/link'
import { motion } from 'framer-motion'

export default function HeroContent() {
  return (
    <section className="flex-1 flex flex-col items-center justify-center text-center px-6 py-16">
      <motion.div
        className="text-6xl mb-4 cat-eyes"
        animate={{ y: [0, -8, 0] }}
        transition={{ repeat: Infinity, duration: 3, ease: 'easeInOut' }}
      >
        🐈‍⬛⚡
      </motion.div>
      <motion.h1
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, ease: 'easeOut' }}
        className="font-display font-900 text-4xl sm:text-6xl tracking-wide text-neon-purple neon-text mb-4"
      >
        CATSINO.CASINO
      </motion.h1>
      <motion.p
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.1, ease: 'easeOut' }}
        className="max-w-xl text-slate-300 text-sm sm:text-base mb-2"
      >
        A neon cyber-cat social casino. Free Cat Coins, no real money, no
        cash-outs &mdash; just glowing reels and nine lives of luck.
      </motion.p>
      <motion.p
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.2, ease: 'easeOut' }}
        className="max-w-xl text-slate-500 text-xs mb-8"
      >
        100% virtual currency. For entertainment only. No purchases, no
        sweepstakes, no prizes.
      </motion.p>
      <motion.div
        initial={{ opacity: 0, scale: 0.9 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.5, delay: 0.3, ease: 'easeOut' }}
      >
        <Link
          href="/signup"
          className="inline-block px-8 py-3 rounded-lg bg-neon-purple text-white font-display tracking-widest neon-border hover:opacity-90 transition-opacity"
        >
          GET 10,000 CAT COINS
        </Link>
      </motion.div>
    </section>
  )
}
