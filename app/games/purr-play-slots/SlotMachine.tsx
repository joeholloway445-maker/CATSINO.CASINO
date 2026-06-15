'use client'

import { useState } from 'react'

const SYMBOL_EMOJI: Record<string, string> = {
  CAT: '🐱',
  FISH: '🐟',
  COIN: '🪙',
  YARN: '🧶',
  BOWL: '🥣',
  CROWN: '👑',
}

const BET_OPTIONS = [10, 25, 50, 100, 250, 500, 1000]

const REEL_DELAYS = [600, 1000, 1400]

type SpinResult = {
  reels: string[]
  win: number
  multiplier: number
  balance: number
}

export default function SlotMachine({ initialBalance }: { initialBalance: number }) {
  const [balance, setBalance] = useState(initialBalance)
  const [bet, setBet] = useState(100)
  const [reels, setReels] = useState<string[]>(['CAT', 'FISH', 'COIN'])
  const [spinning, setSpinning] = useState<boolean[]>([false, false, false])
  const [lastWin, setLastWin] = useState<number | null>(null)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  async function spin() {
    if (busy) return
    if (bet > balance) {
      setError('Not enough Cat Coins for that bet.')
      return
    }

    setError('')
    setLastWin(null)
    setBusy(true)
    setSpinning([true, true, true])

    try {
      const res = await fetch('/api/spin', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ game: 'purr_play_slots', bet }),
      })

      const data = await res.json()

      if (!res.ok) {
        setError(data.error ?? 'Spin failed')
        setSpinning([false, false, false])
        setBusy(false)
        return
      }

      const result = data as SpinResult

      // Staggered reel stops for anticipation
      REEL_DELAYS.forEach((delay, i) => {
        setTimeout(() => {
          setReels((prev) => {
            const next = [...prev]
            next[i] = result.reels[i]
            return next
          })
          setSpinning((prev) => {
            const next = [...prev]
            next[i] = false
            return next
          })

          if (i === REEL_DELAYS.length - 1) {
            setBalance(result.balance)
            setLastWin(result.win)
            setBusy(false)
          }
        }, delay)
      })
    } catch {
      setError('Network error. Try again.')
      setSpinning([false, false, false])
      setBusy(false)
    }
  }

  const isJackpot = lastWin !== null && lastWin >= bet * 50
  const isWin = lastWin !== null && lastWin > 0

  return (
    <div className="rounded-2xl border border-neon-purple/40 bg-[#0a0813]/90 p-6 neon-border">
      <div className={`flex justify-center gap-4 mb-6 ${isJackpot ? 'pulse-win' : ''}`}>
        {reels.map((symbol, i) => (
          <div
            key={i}
            className={`w-24 h-24 sm:w-28 sm:h-28 rounded-xl border border-neon-cyan/40 bg-black/60 flex items-center justify-center text-5xl ${
              spinning[i] ? 'reel-spinning opacity-60' : ''
            }`}
          >
            {SYMBOL_EMOJI[symbol] ?? '❓'}
          </div>
        ))}
      </div>

      {lastWin !== null && (
        <div
          className={`text-center mb-4 font-display tracking-widest text-sm ${
            isJackpot ? 'text-neon-pink neon-text' : isWin ? 'text-neon-green' : 'text-slate-500'
          }`}
        >
          {isJackpot
            ? `👑 JACKPOT! +${lastWin.toLocaleString()} CAT COINS!`
            : isWin
              ? `+${lastWin.toLocaleString()} Cat Coins`
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
          <button
            key={amount}
            onClick={() => setBet(amount)}
            disabled={busy}
            className={`px-3 py-1.5 rounded-lg text-xs font-mono border transition-colors ${
              bet === amount
                ? 'border-neon-cyan text-neon-cyan bg-neon-cyan/10'
                : 'border-slate-700 text-slate-400 hover:border-neon-cyan/40'
            } disabled:opacity-40`}
          >
            {amount.toLocaleString()}
          </button>
        ))}
      </div>

      <div className="flex items-center justify-between mb-4 text-xs font-mono text-slate-400">
        <span>Balance: <span className="text-neon-green">{balance.toLocaleString()}</span> 🪙</span>
        <span>Bet: <span className="text-neon-cyan">{bet.toLocaleString()}</span> 🪙</span>
      </div>

      <button
        onClick={spin}
        disabled={busy || bet > balance}
        className="w-full py-4 rounded-xl bg-neon-purple text-white font-display text-lg tracking-[0.3em] disabled:opacity-40 hover:opacity-90 transition-opacity"
      >
        {busy ? 'SPINNING...' : 'SPIN'}
      </button>
    </div>
  )
}
