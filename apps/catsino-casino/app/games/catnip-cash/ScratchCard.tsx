'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import confetti from 'canvas-confetti'

const BET_OPTIONS = [10, 25, 50, 100, 250, 500, 1000]

interface ScratchResult {
  grid: string[]
  matches: number
  multiplier: number
  win: number
  balance: number
}

export default function ScratchCard({ initialBalance }: { initialBalance: number }) {
  const [balance, setBalance] = useState(initialBalance)
  const [bet, setBet] = useState(25)
  const [loading, setLoading] = useState(false)
  const [result, setResult] = useState<ScratchResult | null>(null)
  const [revealed, setRevealed] = useState<boolean[]>(Array(9).fill(false))
  const [error, setError] = useState<string | null>(null)
  const [phase, setPhase] = useState<'idle' | 'revealing' | 'done'>('idle')

  async function buyCard() {
    if (loading || phase === 'revealing') return
    setError(null)
    setResult(null)
    setRevealed(Array(9).fill(false))
    setPhase('idle')
    setLoading(true)

    try {
      const res = await fetch('/api/scratch-card', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ bet }),
      })
      const data = await res.json()
      if (!res.ok) {
        setError(data.error ?? 'Something went wrong')
        setLoading(false)
        return
      }

      setResult(data)
      setBalance(data.balance)
      setLoading(false)
      setPhase('revealing')

      // Stagger reveal each cell 150ms apart
      for (let i = 0; i < 9; i++) {
        await new Promise<void>((resolve) => setTimeout(resolve, 150))
        setRevealed((prev) => {
          const next = [...prev]
          next[i] = true
          return next
        })
      }

      setPhase('done')

      if (data.multiplier === 100) {
        confetti({
          particleCount: 200,
          spread: 80,
          origin: { y: 0.5 },
          colors: ['#ff2bd6', '#39ff88', '#00f6ff', '#b026ff'],
        })
      } else if (data.win > 0) {
        confetti({
          particleCount: 80,
          spread: 60,
          origin: { y: 0.6 },
          colors: ['#39ff88', '#00f6ff'],
        })
      }

      // Reset board after 2s
      setTimeout(() => {
        setResult(null)
        setRevealed(Array(9).fill(false))
        setPhase('idle')
      }, 2000)
    } catch {
      setError('Network error')
      setLoading(false)
    }
  }

  const isJackpot = result?.multiplier === 100
  const isWin = (result?.win ?? 0) > 0

  return (
    <div className="flex flex-col items-center gap-6">
      {/* Balance */}
      <p className="text-xs text-slate-400">
        Balance: <span className="text-neon-cyan font-bold">{balance.toLocaleString()} Cat Chips</span>
      </p>

      {/* Scratch card grid */}
      <div
        className={`rounded-2xl border-2 p-6 transition-all duration-500 ${
          isJackpot
            ? 'border-neon-pink shadow-[0_0_40px_rgba(255,43,214,0.5)]'
            : isWin
            ? 'border-neon-green shadow-[0_0_30px_rgba(57,255,136,0.4)]'
            : 'border-neon-green/40'
        } bg-[#0a0813]/90`}
      >
        <div className="grid grid-cols-3 gap-3">
          {Array.from({ length: 9 }).map((_, i) => (
            <div
              key={i}
              className="relative w-20 h-20 rounded-xl overflow-hidden"
            >
              {/* Hidden state */}
              <div
                className={`absolute inset-0 flex items-center justify-center bg-[#12082a] border border-neon-green/30 rounded-xl transition-opacity duration-200 ${
                  revealed[i] ? 'opacity-0 pointer-events-none' : 'opacity-100'
                }`}
              >
                <span className="text-2xl text-slate-600">?</span>
              </div>

              {/* Revealed state */}
              <AnimatePresence>
                {revealed[i] && result && (
                  <motion.div
                    key={`cell-${i}`}
                    initial={{ scale: 0.5, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    transition={{ type: 'spring', stiffness: 300, damping: 20 }}
                    className="absolute inset-0 flex items-center justify-center bg-[#0d0520] border border-neon-green/50 rounded-xl"
                  >
                    <span className="text-3xl">{result.grid[i]}</span>
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          ))}
        </div>
      </div>

      {/* Win display */}
      <AnimatePresence>
        {phase === 'done' && result && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0 }}
            className="text-center"
          >
            {isWin ? (
              <p className={`font-display text-xl tracking-widest ${isJackpot ? 'text-neon-pink neon-text' : 'text-neon-green'}`}>
                {isJackpot ? '👑 JACKPOT! ' : ''}+{result.win.toLocaleString()} Cat Chips ({result.multiplier}x)
              </p>
            ) : (
              <p className="text-slate-500 text-sm">No match — try again!</p>
            )}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Bet selector */}
      <div className="flex flex-wrap gap-2 justify-center">
        {BET_OPTIONS.map((opt) => (
          <button
            key={opt}
            onClick={() => setBet(opt)}
            disabled={loading || phase === 'revealing'}
            className={`px-3 py-1.5 rounded-lg text-xs font-bold border transition-all ${
              bet === opt
                ? 'border-neon-green text-neon-green bg-neon-green/10 shadow-[0_0_10px_rgba(57,255,136,0.3)]'
                : 'border-slate-700 text-slate-400 hover:border-slate-500'
            }`}
          >
            {opt.toLocaleString()}
          </button>
        ))}
      </div>

      {/* Buy Card button */}
      <button
        onClick={buyCard}
        disabled={loading || phase === 'revealing'}
        className="px-8 py-3 rounded-xl font-display tracking-widest text-sm border-2 border-neon-green text-neon-green bg-neon-green/10 hover:bg-neon-green/20 hover:shadow-[0_0_20px_rgba(57,255,136,0.4)] transition-all disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {loading ? 'SCRATCHING...' : phase === 'revealing' ? 'REVEALING...' : 'BUY CARD'}
      </button>

      {/* Error */}
      {error && (
        <p className="text-xs text-red-400 text-center">{error}</p>
      )}

      {/* Payout table */}
      <div className="text-xs text-slate-500 text-center space-y-1 mt-2">
        <p className="text-slate-400 font-bold mb-2">PAYOUT TABLE</p>
        {[
          ['3 matches', '1x'],
          ['4 matches', '2x'],
          ['5 matches', '5x'],
          ['6 matches', '10x'],
          ['7 matches', '20x'],
          ['8 matches', '50x'],
          ['9 matches 👑', '100x'],
        ].map(([label, mult]) => (
          <div key={label} className="flex justify-between gap-8">
            <span>{label}</span>
            <span className="text-neon-green">{mult}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
