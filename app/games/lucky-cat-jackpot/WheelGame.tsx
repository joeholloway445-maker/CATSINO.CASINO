'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import confetti from 'canvas-confetti'

const BET_OPTIONS = [10, 25, 50, 100, 250, 500, 1000]

// Index = wheel segment (0-7, clockwise from top). Must match spin_wheel() in
// supabase/migrations/002_lucky_cat_jackpot.sql.
const WHEEL_SEGMENTS = [
  { emoji: '💀', label: '0x', multiplier: 0, color: '#1a1428' },
  { emoji: '🐾', label: '0.5x', multiplier: 0.5, color: '#2a1a3d' },
  { emoji: '💀', label: '0x', multiplier: 0, color: '#1a1428' },
  { emoji: '🐟', label: '1x', multiplier: 1, color: '#102a3d' },
  { emoji: '🎀', label: '2x', multiplier: 2, color: '#2a1a3d' },
  { emoji: '💀', label: '0x', multiplier: 0, color: '#1a1428' },
  { emoji: '👑', label: '5x', multiplier: 5, color: '#10331f' },
  { emoji: '💎', label: '25x', multiplier: 25, color: '#3d1a33' },
]

const SEGMENT_DEG = 360 / WHEEL_SEGMENTS.length

const WHEEL_GRADIENT = `conic-gradient(${WHEEL_SEGMENTS.map((s, i) => {
  const from = i * SEGMENT_DEG
  const to = from + SEGMENT_DEG
  return `${s.color} ${from}deg ${to}deg`
}).join(', ')})`

type SpinResult = {
  segment: number
  multiplier: number
  win: number
  balance: number
}

function fireJackpotConfetti() {
  const colors = ['#b026ff', '#00f6ff', '#39ff88', '#ff2bd6']
  confetti({ particleCount: 160, spread: 110, origin: { y: 0.5 }, colors, scalar: 1.2 })
  setTimeout(
    () => confetti({ particleCount: 120, spread: 130, origin: { y: 0.4 }, colors, scalar: 1 }),
    250,
  )
}

function fireWinConfetti() {
  confetti({
    particleCount: 50,
    spread: 70,
    origin: { y: 0.5 },
    colors: ['#39ff88', '#00f6ff'],
    scalar: 0.8,
  })
}

export default function WheelGame({ initialBalance }: { initialBalance: number }) {
  const [balance, setBalance] = useState(initialBalance)
  const [bet, setBet] = useState(100)
  const [rotation, setRotation] = useState(0)
  const [spinning, setSpinning] = useState(false)
  const [lastWin, setLastWin] = useState<number | null>(null)
  const [lastMultiplier, setLastMultiplier] = useState(0)
  const [error, setError] = useState('')

  async function spin() {
    if (spinning) return
    if (bet > balance) {
      setError('Not enough Cat Coins for that bet.')
      return
    }

    setError('')
    setLastWin(null)
    setSpinning(true)

    try {
      const res = await fetch('/api/spin-wheel', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ bet }),
      })

      const data = await res.json()

      if (!res.ok) {
        setError(data.error ?? 'Spin failed')
        setSpinning(false)
        return
      }

      const result = data as SpinResult
      const spins = 5
      const target = spins * 360 - result.segment * SEGMENT_DEG

      setRotation((prev) => prev - (prev % 360) + target + 360 * Math.ceil(prev / 360))

      setTimeout(() => {
        setSpinning(false)
        setBalance(result.balance)
        setLastWin(result.win)
        setLastMultiplier(result.multiplier)

        if (result.multiplier >= 25) {
          fireJackpotConfetti()
        } else if (result.win > 0) {
          fireWinConfetti()
        }
      }, 3200)
    } catch {
      setError('Network error. Try again.')
      setSpinning(false)
    }
  }

  const isJackpot = lastWin !== null && lastMultiplier >= 25
  const isWin = lastWin !== null && lastWin > 0

  return (
    <div className="rounded-2xl border border-neon-pink/40 bg-[#0a0813]/90 p-6 neon-border">
      <div className="relative w-64 h-64 sm:w-80 sm:h-80 mx-auto mb-6">
        {/* Pointer */}
        <div className="absolute -top-1 left-1/2 -translate-x-1/2 z-10 w-0 h-0 border-l-[14px] border-r-[14px] border-t-[22px] border-l-transparent border-r-transparent border-t-neon-pink drop-shadow-[0_0_8px_rgba(255,43,214,0.8)]" />

        <motion.div
          className="w-full h-full rounded-full border-4 border-neon-pink/60 relative overflow-hidden"
          style={{ background: WHEEL_GRADIENT, boxShadow: '0 0 30px rgba(255,43,214,0.35)' }}
          animate={{ rotate: rotation }}
          transition={{ duration: 3.2, ease: [0.12, 0.8, 0.15, 1] }}
        >
          {WHEEL_SEGMENTS.map((s, i) => {
            const angle = i * SEGMENT_DEG + SEGMENT_DEG / 2
            return (
              <div
                key={i}
                className="absolute inset-0 flex justify-center"
                style={{ transform: `rotate(${angle}deg)` }}
              >
                <div className="flex flex-col items-center gap-0.5 pt-3 sm:pt-4">
                  <span className="text-2xl sm:text-3xl">{s.emoji}</span>
                  <span className="text-[10px] font-mono text-slate-300">{s.label}</span>
                </div>
              </div>
            )
          })}
        </motion.div>

        <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
          <div className="w-10 h-10 rounded-full bg-[#0a0813] border-2 border-neon-pink/60" />
        </div>
      </div>

      {lastWin !== null && (
        <div
          className={`text-center mb-4 font-display tracking-widest text-sm ${
            isJackpot ? 'text-neon-pink neon-text' : isWin ? 'text-neon-green' : 'text-slate-500'
          }`}
        >
          {isJackpot
            ? `💎 JACKPOT! +${lastWin.toLocaleString()} CAT COINS!`
            : isWin
              ? `+${lastWin.toLocaleString()} Cat Coins (${lastMultiplier}x)`
              : 'No win this time. Try again!'}
        </div>
      )}

      {error && (
        <div className="text-center mb-4 text-xs text-red-400 bg-red-950/50 border border-red-900 rounded px-3 py-2">
          {error}
        </div>
      )}

      <div className="flex flex-wrap items-center justify-center gap-2 mb-6">
        {BET_OPTIONS.map((amount) => (
          <motion.button
            key={amount}
            whileTap={{ scale: 0.94 }}
            onClick={() => setBet(amount)}
            disabled={spinning}
            className={`px-3 py-1.5 rounded-lg text-xs font-mono border transition-colors ${
              bet === amount
                ? 'border-neon-pink text-neon-pink bg-neon-pink/10'
                : 'border-slate-700 text-slate-400 hover:border-neon-pink/40'
            } disabled:opacity-40`}
          >
            {amount.toLocaleString()}
          </motion.button>
        ))}
      </div>

      <div className="flex items-center justify-between mb-4 text-xs font-mono text-slate-400">
        <span>Balance: <span className="text-neon-green">{balance.toLocaleString()}</span> 🪙</span>
        <span>Bet: <span className="text-neon-pink">{bet.toLocaleString()}</span> 🪙</span>
      </div>

      <motion.button
        whileTap={{ scale: 0.97 }}
        onClick={spin}
        disabled={spinning || bet > balance}
        className="w-full py-4 rounded-xl bg-neon-pink text-white font-display text-lg tracking-[0.3em] disabled:opacity-40 hover:opacity-90 transition-opacity"
      >
        {spinning ? 'SPINNING...' : 'SPIN'}
      </motion.button>
    </div>
  )
}
