'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import confetti from 'canvas-confetti'

const SUITS = ['🐾', '🐱', '🌟', '🎭']
const VALUES = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
const BET_OPTIONS = [10, 25, 50, 100, 250, 500, 1000]

type GameStatus = 'idle' | 'playing' | 'result'
type GameState = {
  player_hand: number[]
  dealer_hand: number[]
  player_score: number
  dealer_score: number
  deck: number[]
  bet: number
  doubled: boolean
}

function cardLabel(index: number) {
  const value = VALUES[index % 13]
  const suit = SUITS[Math.floor(index / 13)]
  const red = suit === '🐱' || suit === '🎭'
  return { value, suit, red }
}

function CardDisplay({ index, hidden = false, delay = 0 }: { index: number; hidden?: boolean; delay?: number }) {
  if (hidden) {
    return (
      <div className="w-16 h-24 rounded-lg border-2 border-neon-cyan/20 bg-[#0a0813] flex items-center justify-center text-2xl text-slate-700">
        🂠
      </div>
    )
  }
  const { value, suit, red } = cardLabel(index)
  return (
    <motion.div
      initial={{ rotateY: 90, opacity: 0, scale: 0.8 }}
      animate={{ rotateY: 0, opacity: 1, scale: 1 }}
      transition={{ delay, duration: 0.25 }}
      className="w-16 h-24 rounded-lg border-2 border-neon-cyan/30 bg-[#0d0a1a] flex flex-col items-center justify-center gap-1"
    >
      <span className={`text-base font-bold ${red ? 'text-red-400' : 'text-white'}`}>{value}</span>
      <span className="text-xl">{suit}</span>
    </motion.div>
  )
}

export default function BlackjackGame({ initialBalance }: { initialBalance: number }) {
  const [balance, setBalance] = useState(initialBalance)
  const [bet, setBet] = useState(25)
  const [status, setStatus] = useState<GameStatus>('idle')
  const [gameState, setGameState] = useState<GameState | null>(null)
  const [dealerReveal, setDealerReveal] = useState(false)
  const [resultMsg, setResultMsg] = useState('')
  const [lastWin, setLastWin] = useState(0)
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')

  async function callApi(action: string, extraBet?: number) {
    setLoading(true)
    setMessage('')
    const res = await fetch('/api/blackjack', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        action,
        bet: action === 'deal' ? bet : (extraBet ?? gameState?.bet ?? 0),
        game_state: action === 'deal' ? null : gameState,
      }),
    })
    const data = await res.json()
    if (data.error) {
      setMessage(data.error)
      setLoading(false)
      return null
    }
    return data
  }

  async function deal() {
    if (balance < bet) return
    const data = await callApi('deal')
    if (!data) return
    setGameState(data.game_state)
    setBalance(data.new_balance)
    setStatus('playing')
    setDealerReveal(false)
    setResultMsg('')
    setLastWin(0)
    setLoading(false)
  }

  async function action(act: 'hit' | 'stand' | 'double') {
    const data = await callApi(act)
    if (!data) return
    setGameState(data.game_state)
    setBalance(data.new_balance)
    if (data.done) {
      setDealerReveal(true)
      setResultMsg(data.result)
      setLastWin(data.win)
      setStatus('result')
      if (data.win > 0) {
        confetti({ particleCount: data.result === 'blackjack' ? 150 : 60, spread: 80, origin: { y: 0.5 } })
      }
    }
    setLoading(false)
  }

  const gs = gameState
  const playerScore = gs?.player_score ?? 0
  const dealerScore = gs?.dealer_score ?? 0

  const resultColor = resultMsg.includes('WIN') || resultMsg === 'blackjack'
    ? 'text-neon-green' : resultMsg === 'PUSH' ? 'text-yellow-400' : 'text-red-400'

  return (
    <div className="space-y-6">
      {/* Dealer hand */}
      <div className="rounded-xl border border-neon-purple/20 bg-[#0a0813]/60 p-5">
        <p className="text-xs text-slate-500 mb-3 font-display tracking-wider">
          DEALER {dealerReveal ? `— ${dealerScore}` : ''}
        </p>
        <div className="flex gap-2 flex-wrap min-h-[96px]">
          {gs ? gs.dealer_hand.map((c, i) => (
            <CardDisplay key={i} index={c} hidden={i === 1 && !dealerReveal} delay={i * 0.1} />
          )) : (
            <div className="text-slate-700 text-sm self-center">Waiting for deal…</div>
          )}
        </div>
      </div>

      {/* Player hand */}
      <div className="rounded-xl border border-neon-cyan/20 bg-[#0a0813]/60 p-5">
        <p className="text-xs text-slate-500 mb-3 font-display tracking-wider">
          YOU — {playerScore}
          {playerScore > 21 && <span className="text-red-400 ml-2">BUST</span>}
          {playerScore === 21 && gs && gs.player_hand.length === 2 && <span className="text-neon-green ml-2">BLACKJACK!</span>}
        </p>
        <div className="flex gap-2 flex-wrap min-h-[96px]">
          {gs ? gs.player_hand.map((c, i) => (
            <CardDisplay key={i} index={c} delay={i * 0.1} />
          )) : (
            <div className="text-slate-700 text-sm self-center">Place your bet and deal</div>
          )}
        </div>
      </div>

      {/* Result */}
      <AnimatePresence>
        {status === 'result' && resultMsg && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0 }}
            className="text-center"
          >
            <p className={`font-display text-2xl tracking-widest ${resultColor}`}>
              {resultMsg.toUpperCase()} {lastWin > 0 ? `+${lastWin.toLocaleString()} 🪙` : ''}
            </p>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Bet selector (only when idle/result) */}
      {status !== 'playing' && (
        <div className="flex gap-2 justify-center flex-wrap">
          {BET_OPTIONS.map(b => (
            <button
              key={b}
              onClick={() => setBet(b)}
              className={`px-3 py-1.5 rounded-lg text-xs font-display tracking-wider border transition-all
                ${bet === b ? 'border-neon-cyan bg-neon-cyan/10 text-neon-cyan' : 'border-slate-700 text-slate-500 hover:border-slate-500'}`}
            >
              {b.toLocaleString()}
            </button>
          ))}
        </div>
      )}

      {/* Action buttons */}
      <div className="flex gap-3 justify-center flex-wrap">
        {status !== 'playing' ? (
          <motion.button
            whileTap={{ scale: 0.95 }}
            onClick={deal}
            disabled={loading || balance < bet}
            className="px-10 py-3 rounded-xl bg-neon-cyan/10 border border-neon-cyan text-neon-cyan font-display tracking-widest text-sm hover:bg-neon-cyan/20 transition-all disabled:opacity-40"
          >
            {loading ? 'DEALING…' : 'DEAL'}
          </motion.button>
        ) : (
          <>
            <motion.button whileTap={{ scale: 0.95 }} onClick={() => action('hit')} disabled={loading}
              className="px-6 py-3 rounded-xl bg-neon-green/10 border border-neon-green text-neon-green font-display tracking-widest text-sm hover:bg-neon-green/20 transition-all disabled:opacity-40">
              HIT
            </motion.button>
            <motion.button whileTap={{ scale: 0.95 }} onClick={() => action('stand')} disabled={loading}
              className="px-6 py-3 rounded-xl bg-neon-purple/10 border border-neon-purple text-neon-purple font-display tracking-widest text-sm hover:bg-neon-purple/20 transition-all disabled:opacity-40">
              STAND
            </motion.button>
            {gs && gs.player_hand.length === 2 && balance >= gs.bet && (
              <motion.button whileTap={{ scale: 0.95 }} onClick={() => action('double')} disabled={loading}
                className="px-6 py-3 rounded-xl bg-neon-pink/10 border border-neon-pink text-neon-pink font-display tracking-widest text-sm hover:bg-neon-pink/20 transition-all disabled:opacity-40">
                DOUBLE
              </motion.button>
            )}
          </>
        )}
      </div>

      <div className="text-center text-xs text-slate-500">
        Balance: <span className="text-neon-green font-bold">{balance.toLocaleString()} 🪙</span>
        {gs && <span className="ml-4">Bet: <span className="text-neon-cyan">{gs.bet.toLocaleString()} 🪙</span></span>}
        {message && <span className="text-red-400 ml-4">{message}</span>}
      </div>
    </div>
  )
}
