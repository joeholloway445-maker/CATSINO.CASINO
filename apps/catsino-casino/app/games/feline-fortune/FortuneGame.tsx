'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import confetti from 'canvas-confetti'

const BET_OPTIONS = [10, 25, 50, 100, 250, 500, 1000]

const FORTUNE_CARDS = [
  { id: 0, emoji: '🔮', name: 'The Oracle', desc: 'Foresight grants triple your bet', mult: 3, color: '#B026FF' },
  { id: 1, emoji: '🐱', name: 'Lucky Cat', desc: 'The golden cat blesses you with 2x', mult: 2, color: '#FFD700' },
  { id: 2, emoji: '🌙', name: 'Moon Omen', desc: 'Moonlight doubles your coins', mult: 2, color: '#00CED1' },
  { id: 3, emoji: '⭐', name: 'Star Blessing', desc: 'Stars align for 1.5x', mult: 1.5, color: '#39FF88' },
  { id: 4, emoji: '🎭', name: 'The Trickster', desc: 'Fool\'s luck returns your bet', mult: 1, color: '#FF9500' },
  { id: 5, emoji: '🌀', name: 'Void', desc: 'The void takes all', mult: 0, color: '#333344' },
  { id: 6, emoji: '👑', name: 'Royal Fortune', desc: 'Crown grants 5x the prize', mult: 5, color: '#FFD700' },
  { id: 7, emoji: '🌿', name: 'Wild Growth', desc: 'Nature multiplies your bet 1.5x', mult: 1.5, color: '#228B22' },
  { id: 8, emoji: '💎', name: 'Diamond Destiny', desc: 'Rare gem grants 10x jackpot!', mult: 10, color: '#00F6FF' },
]

export default function FortuneGame({ initialBalance }: { initialBalance: number }) {
  const [balance, setBalance] = useState(initialBalance)
  const [bet, setBet] = useState(25)
  const [drawnCard, setDrawnCard] = useState<typeof FORTUNE_CARDS[0] | null>(null)
  const [revealed, setRevealed] = useState(false)
  const [win, setWin] = useState(0)
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')
  const [fortune, setFortune] = useState('')

  const FORTUNES = [
    "The cat who hesitates loses the fish.",
    "Nine lives means nine chances — take them all.",
    "Luck favors the cat who grooms well.",
    "Your whiskers sense riches nearby.",
    "The yarn of fate unravels in your favor.",
    "A purring cat draws fortune closer.",
    "Meow with confidence; wealth shall follow.",
    "The sleeping cat dreams of endless coins.",
  ]

  async function drawFortune() {
    if (loading || balance < bet) return
    setLoading(true)
    setMessage('')
    setRevealed(false)
    setDrawnCard(null)
    setWin(0)
    setFortune(FORTUNES[Math.floor(Math.random() * FORTUNES.length)])

    const res = await fetch('/api/fortune', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ bet }),
    })
    const data = await res.json()
    if (data.error) { setMessage(data.error); setLoading(false); return }

    setBalance(data.new_balance)
    setWin(data.win)
    const card = FORTUNE_CARDS[data.card_index] ?? FORTUNE_CARDS[5]
    setDrawnCard(card)

    // Animate reveal after a moment
    setTimeout(() => {
      setRevealed(true)
      setLoading(false)
      if (data.win > 0) {
        if (data.multiplier >= 5) {
          confetti({ particleCount: 200, spread: 120, origin: { y: 0.4 }, colors: ['#B026FF', '#FFD700', '#00F6FF'] })
        } else if (data.multiplier >= 2) {
          confetti({ particleCount: 80, spread: 90, origin: { y: 0.5 } })
        }
      }
    }, 800)
  }

  return (
    <div className="space-y-8 text-center">
      {/* Fortune card display */}
      <div className="flex justify-center">
        <div className="relative w-48 h-72">
          <AnimatePresence mode="wait">
            {!drawnCard || !revealed ? (
              <motion.div
                key="back"
                initial={{ rotateY: 0 }}
                exit={{ rotateY: 90 }}
                transition={{ duration: 0.4 }}
                className="absolute inset-0 rounded-2xl border-2 border-neon-purple/40 bg-gradient-to-b from-[#1a0a2e] to-[#0a0813] flex items-center justify-center"
              >
                {loading ? (
                  <motion.div animate={{ rotate: 360 }} transition={{ duration: 1, repeat: Infinity, ease: 'linear' }}>
                    <span className="text-5xl">🔮</span>
                  </motion.div>
                ) : (
                  <span className="text-5xl opacity-40">🂠</span>
                )}
              </motion.div>
            ) : (
              <motion.div
                key="front"
                initial={{ rotateY: -90 }}
                animate={{ rotateY: 0 }}
                transition={{ duration: 0.4 }}
                className="absolute inset-0 rounded-2xl border-2 flex flex-col items-center justify-center gap-3 p-4"
                style={{ borderColor: drawnCard.color, boxShadow: `0 0 30px ${drawnCard.color}40`, background: `radial-gradient(circle at center, ${drawnCard.color}10 0%, #0a0813 70%)` }}
              >
                <span className="text-6xl">{drawnCard.emoji}</span>
                <p className="font-display tracking-widest text-sm" style={{ color: drawnCard.color }}>{drawnCard.name}</p>
                <p className="text-xs text-slate-400 text-center">{drawnCard.desc}</p>
                {drawnCard.mult > 0 ? (
                  <p className="font-display text-xl" style={{ color: drawnCard.color }}>
                    {win > 0 ? `+${win.toLocaleString()} 🪙` : `${drawnCard.mult}x`}
                  </p>
                ) : (
                  <p className="text-red-400 font-display">No win</p>
                )}
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>

      {/* Fortune text */}
      <AnimatePresence>
        {revealed && fortune && (
          <motion.p initial={{ opacity: 0, y: 5 }} animate={{ opacity: 1, y: 0 }} className="text-slate-400 text-sm italic">
            &ldquo;{fortune}&rdquo;
          </motion.p>
        )}
      </AnimatePresence>

      {/* Card grid preview */}
      <div className="grid grid-cols-9 gap-1 justify-center">
        {FORTUNE_CARDS.map(c => (
          <div key={c.id} className="w-8 h-10 rounded border flex items-center justify-center text-lg"
            style={{ borderColor: drawnCard?.id === c.id && revealed ? c.color : '#333', background: drawnCard?.id === c.id && revealed ? `${c.color}20` : 'transparent' }}>
            {c.emoji}
          </div>
        ))}
      </div>

      {/* Bet selector */}
      <div className="flex gap-2 justify-center flex-wrap">
        {BET_OPTIONS.map(b => (
          <button key={b} onClick={() => setBet(b)}
            className={`px-3 py-1.5 rounded-lg text-xs font-display tracking-wider border transition-all
              ${bet === b ? 'border-neon-purple bg-neon-purple/10 text-neon-purple' : 'border-slate-700 text-slate-500 hover:border-slate-500'}`}>
            {b.toLocaleString()}
          </button>
        ))}
      </div>

      <motion.button whileTap={{ scale: 0.95 }} onClick={drawFortune}
        disabled={loading || balance < bet}
        className="px-12 py-3 rounded-xl bg-neon-purple/10 border border-neon-purple text-neon-purple font-display tracking-widest text-sm hover:bg-neon-purple/20 hover:shadow-[0_0_20px_rgba(176,38,255,0.4)] transition-all disabled:opacity-40">
        {loading ? 'DRAWING…' : 'DRAW FORTUNE'}
      </motion.button>

      <div className="text-xs text-slate-500">
        Balance: <span className="text-neon-green font-bold">{balance.toLocaleString()} 🪙</span>
        {message && <span className="text-red-400 ml-4">{message}</span>}
      </div>
    </div>
  )
}
