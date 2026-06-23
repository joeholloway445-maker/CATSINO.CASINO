'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import confetti from 'canvas-confetti'

const SUITS = ['🐾', '🐱', '🌟', '🎭']
const VALUES = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
const BET_OPTIONS = [10, 25, 50, 100, 250, 500, 1000]

const HAND_PAYOUTS: [string, number][] = [
  ['Royal Flush', 250],
  ['Straight Flush', 50],
  ['Four of a Kind', 25],
  ['Full House', 9],
  ['Flush', 6],
  ['Straight', 4],
  ['Three of a Kind', 3],
  ['Two Pair', 2],
  ['Jacks or Better', 1],
]

function cardLabel(index: number): { value: string; suit: string; red: boolean } {
  const value = VALUES[index % 13]
  const suit = SUITS[Math.floor(index / 13)]
  const red = suit === '🐱' || suit === '🎭'
  return { value, suit, red }
}

export default function PokerGame({ initialBalance }: { initialBalance: number }) {
  const [balance, setBalance] = useState(initialBalance)
  const [bet, setBet] = useState(25)
  const [phase, setPhase] = useState<'idle' | 'held' | 'result'>('idle')
  const [cards, setCards] = useState<number[]>([])
  const [held, setHeld] = useState<boolean[]>([false, false, false, false, false])
  const [handRank, setHandRank] = useState('')
  const [lastWin, setLastWin] = useState(0)
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')

  async function deal() {
    if (loading || balance < bet) return
    setLoading(true)
    setMessage('')
    setHandRank('')
    setLastWin(0)
    setHeld([false, false, false, false, false])

    const res = await fetch('/api/poker', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ bet, phase: 'deal' }),
    })
    const data = await res.json()
    if (data.error) { setMessage(data.error); setLoading(false); return }

    setCards(data.cards)
    setBalance(data.new_balance)
    setPhase('held')
    setLoading(false)
  }

  async function draw() {
    if (loading) return
    setLoading(true)
    const heldIndices = held.map((h, i) => h ? i : -1).filter(i => i >= 0)
    const heldCards = heldIndices.map(i => cards[i])

    const res = await fetch('/api/poker', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ bet, held_indices: heldIndices, held_cards: heldCards, phase: 'draw' }),
    })
    const data = await res.json()
    if (data.error) { setMessage(data.error); setLoading(false); return }

    setCards(data.cards)
    setBalance(data.new_balance)
    setHandRank(data.hand_rank)
    setLastWin(data.win)
    setPhase('result')

    if (data.win > 0) {
      if (data.hand_rank === 'Royal Flush' || data.hand_rank === 'Straight Flush') {
        confetti({ particleCount: 200, spread: 120, origin: { y: 0.5 }, colors: ['#00F6FF', '#B026FF', '#FF2BD6'] })
      } else {
        confetti({ particleCount: 60, spread: 70, origin: { y: 0.6 } })
      }
    }
    setLoading(false)
  }

  function toggleHold(i: number) {
    if (phase !== 'held') return
    setHeld(h => h.map((v, idx) => idx === i ? !v : v))
  }

  const isIdle = phase === 'idle' || phase === 'result'

  return (
    <div className="space-y-6">
      {/* Payout table */}
      <div className="rounded-xl border border-neon-cyan/20 bg-[#0a0813]/60 p-4">
        <div className="grid grid-cols-2 gap-x-8 gap-y-1">
          {HAND_PAYOUTS.map(([rank, mult]) => (
            <div key={rank} className={`flex justify-between text-xs ${handRank === rank ? 'text-neon-cyan font-bold' : 'text-slate-500'}`}>
              <span>{rank}</span>
              <span>{mult}x</span>
            </div>
          ))}
        </div>
      </div>

      {/* Cards */}
      <div className="flex gap-3 justify-center">
        {phase === 'idle' ? (
          Array.from({ length: 5 }).map((_, i) => (
            <div key={i} className="w-20 h-32 rounded-xl border-2 border-neon-cyan/20 bg-[#0a0813] flex items-center justify-center text-3xl text-slate-700">
              🂠
            </div>
          ))
        ) : (
          cards.map((cardIdx, i) => {
            const { value, suit, red } = cardLabel(cardIdx)
            return (
              <motion.div
                key={i}
                initial={{ rotateY: 90, opacity: 0 }}
                animate={{ rotateY: 0, opacity: 1 }}
                transition={{ delay: held[i] ? 0 : i * 0.08, duration: 0.3 }}
                onClick={() => toggleHold(i)}
                className={`w-20 h-32 rounded-xl border-2 flex flex-col items-center justify-center cursor-pointer select-none transition-all
                  ${held[i] ? 'border-yellow-400 shadow-[0_0_16px_rgba(250,204,21,0.5)] bg-yellow-900/20' : 'border-neon-cyan/30 bg-[#0a0813]'}
                `}
              >
                <span className={`text-xl font-bold ${red ? 'text-red-400' : 'text-white'}`}>{value}</span>
                <span className="text-2xl">{suit}</span>
                {held[i] && (
                  <span className="text-xs text-yellow-400 font-display tracking-wider mt-1">HOLD</span>
                )}
              </motion.div>
            )
          })
        )}
      </div>

      {/* Win display */}
      <AnimatePresence>
        {phase === 'result' && (
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0 }}
            className="text-center"
          >
            {handRank ? (
              <p className={`font-display text-xl tracking-widest ${lastWin > 0 ? 'text-neon-cyan neon-text' : 'text-slate-500'}`}>
                {handRank || 'No Win'} {lastWin > 0 ? `+${lastWin.toLocaleString()} 🪙` : ''}
              </p>
            ) : (
              <p className="text-slate-500 font-display tracking-widest">NO WIN</p>
            )}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Bet selector */}
      <div className="flex gap-2 justify-center flex-wrap">
        {BET_OPTIONS.map(b => (
          <button
            key={b}
            onClick={() => isIdle && setBet(b)}
            disabled={!isIdle}
            className={`px-3 py-1.5 rounded-lg text-xs font-display tracking-wider border transition-all
              ${bet === b ? 'border-neon-cyan bg-neon-cyan/10 text-neon-cyan' : 'border-slate-700 text-slate-500 hover:border-slate-500'}
              disabled:opacity-40`}
          >
            {b.toLocaleString()}
          </button>
        ))}
      </div>

      {/* Action button */}
      <div className="flex justify-center gap-4">
        {isIdle ? (
          <motion.button
            whileTap={{ scale: 0.95 }}
            onClick={deal}
            disabled={loading || balance < bet}
            className="px-10 py-3 rounded-xl bg-neon-cyan/10 border border-neon-cyan text-neon-cyan font-display tracking-widest text-sm hover:bg-neon-cyan/20 hover:shadow-[0_0_20px_rgba(0,246,255,0.4)] transition-all disabled:opacity-40"
          >
            {loading ? 'DEALING...' : 'DEAL'}
          </motion.button>
        ) : (
          <motion.button
            whileTap={{ scale: 0.95 }}
            onClick={draw}
            disabled={loading}
            className="px-10 py-3 rounded-xl bg-neon-purple/10 border border-neon-purple text-neon-purple font-display tracking-widest text-sm hover:bg-neon-purple/20 hover:shadow-[0_0_20px_rgba(176,38,255,0.4)] transition-all disabled:opacity-40"
          >
            {loading ? 'DRAWING...' : 'DRAW'}
          </motion.button>
        )}
      </div>

      {/* Balance */}
      <div className="text-center text-xs text-slate-500">
        Balance: <span className="text-neon-green font-bold">{balance.toLocaleString()} 🪙</span>
        {message && <span className="text-red-400 ml-4">{message}</span>}
      </div>
    </div>
  )
}
