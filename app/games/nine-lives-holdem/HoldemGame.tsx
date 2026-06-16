'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import confetti from 'canvas-confetti'

const SUITS = ['🐾', '🐱', '🌟', '🎭']
const VALUES = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
const BET_OPTIONS = [10, 25, 50, 100, 250, 500, 1000]
const MAX_LIVES = 9

type Phase = 'idle' | 'preflop' | 'flop' | 'turn' | 'river' | 'result'

type GameState = {
  player_hand: number[]
  dealer_hand: number[]
  community: number[]
  deck: number[]
  pot: number
  ante: number
  phase: string
  dealer_action: string
}

function cardLabel(idx: number) {
  return { value: VALUES[idx % 13], suit: SUITS[Math.floor(idx / 13)], red: Math.floor(idx / 13) % 2 === 1 }
}

function Card({ idx, hidden = false, delay = 0 }: { idx: number; hidden?: boolean; delay?: number }) {
  if (hidden) return (
    <div className="w-14 h-20 rounded-lg border-2 border-neon-green/20 bg-[#0a0813] flex items-center justify-center text-xl text-slate-700">🂠</div>
  )
  const { value, suit, red } = cardLabel(idx)
  return (
    <motion.div
      initial={{ rotateY: 90, opacity: 0 }}
      animate={{ rotateY: 0, opacity: 1 }}
      transition={{ delay, duration: 0.22 }}
      className="w-14 h-20 rounded-lg border-2 border-neon-green/30 bg-[#0d0a1a] flex flex-col items-center justify-center gap-0.5"
    >
      <span className={`text-sm font-bold ${red ? 'text-red-400' : 'text-white'}`}>{value}</span>
      <span className="text-lg">{suit}</span>
    </motion.div>
  )
}

export default function HoldemGame({ initialBalance }: { initialBalance: number }) {
  const [balance, setBalance] = useState(initialBalance)
  const [bet, setBet] = useState(25)
  const [lives, setLives] = useState(MAX_LIVES)
  const [phase, setPhase] = useState<Phase>('idle')
  const [gs, setGs] = useState<GameState | null>(null)
  const [resultMsg, setResultMsg] = useState('')
  const [lastWin, setLastWin] = useState(0)
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')
  const [dealerInfo, setDealerInfo] = useState('')

  async function call(action: string, extraBet = 0) {
    setLoading(true)
    setMessage('')
    const res = await fetch('/api/holdem', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        action,
        bet: action === 'deal' ? bet : extraBet,
        game_state: action === 'deal' ? null : gs,
      }),
    })
    const data = await res.json()
    if (data.error) { setMessage(data.error); setLoading(false); return null }
    return data
  }

  async function deal() {
    if (balance < bet) return
    const data = await call('deal')
    if (!data) return
    setGs(data.game_state)
    setBalance(data.new_balance)
    setPhase('preflop')
    setResultMsg('')
    setLastWin(0)
    setDealerInfo(`Dealer ${data.game_state.dealer_action}`)
    setLoading(false)
  }

  async function action(act: 'call' | 'raise' | 'fold' | 'check', raiseBet = 0) {
    const data = await call(act, raiseBet)
    if (!data) return
    setGs(data.game_state)
    setBalance(data.new_balance)
    setDealerInfo(`Dealer ${data.game_state?.dealer_action ?? ''}`)
    if (data.done) {
      setPhase('result')
      setResultMsg(data.result)
      setLastWin(data.win)
      if (data.win > data.game_state?.ante) {
        confetti({ particleCount: 80, spread: 80, origin: { y: 0.5 }, colors: ['#39FF88', '#B026FF', '#00F6FF'] })
      } else if (data.result === 'FOLD' || data.win === 0) {
        setLives(l => Math.max(0, l - 1))
      }
    } else {
      const phases: Record<string, Phase> = { preflop: 'flop', flop: 'turn', turn: 'river', river: 'result' }
      setPhase(phases[data.game_state.phase] ?? phase)
    }
    setLoading(false)
  }

  const isIdle = phase === 'idle' || phase === 'result'
  const resultColor = resultMsg === 'WIN' ? 'text-neon-green' : resultMsg === 'PUSH' ? 'text-yellow-400' : 'text-red-400'

  return (
    <div className="space-y-5">
      {/* Lives */}
      <div className="flex items-center gap-2">
        <span className="text-xs text-slate-500 font-display tracking-wider">LIVES:</span>
        {Array.from({ length: MAX_LIVES }).map((_, i) => (
          <span key={i} className={`text-lg ${i < lives ? 'opacity-100' : 'opacity-20'}`}>❤️</span>
        ))}
      </div>

      {/* Community cards */}
      <div className="rounded-xl border border-neon-green/20 bg-[#0a0813]/60 p-4">
        <p className="text-xs text-slate-500 mb-2 font-display tracking-wider">COMMUNITY</p>
        <div className="flex gap-2 min-h-[80px] items-center">
          {gs ? (
            gs.community.length > 0
              ? gs.community.map((c, i) => <Card key={i} idx={c} delay={i * 0.1} />)
              : <span className="text-slate-700 text-sm">Flop reveals after bets…</span>
          ) : (
            <span className="text-slate-700 text-sm">Deal to start</span>
          )}
        </div>
      </div>

      {/* Dealer hand */}
      <div className="rounded-xl border border-neon-purple/20 bg-[#0a0813]/60 p-4">
        <div className="flex items-center gap-3 mb-2">
          <p className="text-xs text-slate-500 font-display tracking-wider">DEALER</p>
          {dealerInfo && <span className="text-xs text-neon-purple">{dealerInfo}</span>}
        </div>
        <div className="flex gap-2 min-h-[80px] items-center">
          {gs ? gs.dealer_hand.map((c, i) => (
            <Card key={i} idx={c} hidden={phase !== 'result' && i === 1} delay={i * 0.1} />
          )) : null}
        </div>
      </div>

      {/* Player hand */}
      <div className="rounded-xl border border-neon-cyan/20 bg-[#0a0813]/60 p-4">
        <p className="text-xs text-slate-500 mb-2 font-display tracking-wider">YOUR HAND</p>
        <div className="flex gap-2 min-h-[80px] items-center">
          {gs ? gs.player_hand.map((c, i) => <Card key={i} idx={c} delay={i * 0.1} />) : null}
        </div>
      </div>

      {/* Pot */}
      {gs && (
        <div className="text-center text-xs text-slate-400">
          POT: <span className="text-neon-green font-bold">{gs.pot.toLocaleString()} 🪙</span>
          <span className="mx-2">|</span>
          ANTE: <span className="text-neon-cyan">{gs.ante.toLocaleString()} 🪙</span>
        </div>
      )}

      {/* Result */}
      <AnimatePresence>
        {phase === 'result' && resultMsg && (
          <motion.div initial={{ opacity: 0, scale: 0.8 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0 }} className="text-center">
            <p className={`font-display text-2xl tracking-widest ${resultColor}`}>
              {resultMsg} {lastWin > 0 ? `+${lastWin.toLocaleString()} 🪙` : ''}
            </p>
            {lives === 0 && <p className="text-red-400 text-sm mt-1">Out of lives! Refresh to restart.</p>}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Bet selector */}
      {isIdle && (
        <div className="flex gap-2 justify-center flex-wrap">
          {BET_OPTIONS.map(b => (
            <button key={b} onClick={() => setBet(b)}
              className={`px-3 py-1.5 rounded-lg text-xs font-display tracking-wider border transition-all
                ${bet === b ? 'border-neon-green bg-neon-green/10 text-neon-green' : 'border-slate-700 text-slate-500 hover:border-slate-500'}`}>
              {b.toLocaleString()}
            </button>
          ))}
        </div>
      )}

      {/* Action buttons */}
      <div className="flex gap-2 justify-center flex-wrap">
        {isIdle ? (
          <motion.button whileTap={{ scale: 0.95 }} onClick={deal}
            disabled={loading || balance < bet || lives === 0}
            className="px-10 py-3 rounded-xl bg-neon-green/10 border border-neon-green text-neon-green font-display tracking-widest text-sm hover:bg-neon-green/20 transition-all disabled:opacity-40">
            {loading ? 'DEALING…' : 'DEAL'}
          </motion.button>
        ) : (
          <>
            <motion.button whileTap={{ scale: 0.95 }} onClick={() => action('call', gs?.ante ?? 0)}
              disabled={loading}
              className="px-5 py-2.5 rounded-xl bg-neon-green/10 border border-neon-green text-neon-green font-display tracking-widest text-xs hover:bg-neon-green/20 transition-all disabled:opacity-40">
              CALL {gs?.ante.toLocaleString()}
            </motion.button>
            <motion.button whileTap={{ scale: 0.95 }} onClick={() => action('check')}
              disabled={loading}
              className="px-5 py-2.5 rounded-xl bg-neon-cyan/10 border border-neon-cyan text-neon-cyan font-display tracking-widest text-xs hover:bg-neon-cyan/20 transition-all disabled:opacity-40">
              CHECK
            </motion.button>
            <motion.button whileTap={{ scale: 0.95 }} onClick={() => action('raise', (gs?.ante ?? 0) * 2)}
              disabled={loading || balance < (gs?.ante ?? 0) * 2}
              className="px-5 py-2.5 rounded-xl bg-neon-purple/10 border border-neon-purple text-neon-purple font-display tracking-widest text-xs hover:bg-neon-purple/20 transition-all disabled:opacity-40">
              RAISE 2x
            </motion.button>
            <motion.button whileTap={{ scale: 0.95 }} onClick={() => action('fold')}
              disabled={loading}
              className="px-5 py-2.5 rounded-xl bg-red-900/20 border border-red-600 text-red-400 font-display tracking-widest text-xs hover:bg-red-900/30 transition-all disabled:opacity-40">
              FOLD
            </motion.button>
          </>
        )}
      </div>

      <div className="text-center text-xs text-slate-500">
        Balance: <span className="text-neon-green font-bold">{balance.toLocaleString()} 🪙</span>
        {message && <span className="text-red-400 ml-4">{message}</span>}
      </div>
    </div>
  )
}
