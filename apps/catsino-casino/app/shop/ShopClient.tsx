'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import confetti from 'canvas-confetti'

type ShopItem = {
  id: string
  name: string
  desc: string
  icon: string
  price_coins: number
  price_gems: number
  category: string
  color: string
}

const SHOP_ITEMS: ShopItem[] = [
  { id: 'xp_boost', name: 'XP Boost', desc: 'Double XP for 24 hours', icon: '⚡', price_coins: 500, price_gems: 0, category: 'Boosts', color: 'neon-cyan' },
  { id: 'luck_charm', name: 'Lucky Charm', desc: '+10% win chance for 10 games', icon: '🍀', price_coins: 750, price_gems: 0, category: 'Boosts', color: 'neon-green' },
  { id: 'daily_double', name: 'Daily Double', desc: '2x your next daily bonus', icon: '📅', price_coins: 1000, price_gems: 0, category: 'Boosts', color: 'neon-cyan' },
  { id: 'coins_5000', name: '5,000 Coins', desc: 'Refill your coin stack', icon: '🪙', price_coins: 0, price_gems: 50, category: 'Coins', color: 'yellow-400' },
  { id: 'coins_15000', name: '15,000 Coins', desc: 'Premium coin bundle', icon: '💰', price_coins: 0, price_gems: 130, category: 'Coins', color: 'yellow-400' },
  { id: 'crown_frame', name: 'Crown Frame', desc: 'Gold crown profile frame', icon: '👑', price_coins: 5000, price_gems: 0, category: 'Cosmetics', color: 'yellow-400' },
  { id: 'neon_trail', name: 'Neon Trail', desc: 'Cyan trail effect on your cat', icon: '✨', price_coins: 0, price_gems: 50, category: 'Cosmetics', color: 'neon-cyan' },
  { id: 'void_skin', name: 'Void Skin', desc: 'Dark void aesthetic for your profile', icon: '🌑', price_coins: 0, price_gems: 200, category: 'Cosmetics', color: 'neon-purple' },
  { id: 'golden_skin', name: 'Golden Cat', desc: 'Pure gold appearance', icon: '🥇', price_coins: 0, price_gems: 500, category: 'Cosmetics', color: 'yellow-400' },
  { id: 'revive', name: 'Extra Life', desc: 'Restore 1 life in poker/hold\'em', icon: '❤️', price_coins: 250, price_gems: 0, category: 'Consumables', color: 'red-400' },
  { id: 'companion_random', name: 'Mystery Companion', desc: 'Unlock a random rarity-2+ companion', icon: '🎁', price_coins: 2500, price_gems: 0, category: 'Companions', color: 'neon-purple' },
  { id: 'companion_rare', name: 'Rare Companion', desc: 'Guaranteed rarity-4+ companion unlock', icon: '⭐', price_coins: 0, price_gems: 100, category: 'Companions', color: 'neon-pink' },
]

const CATEGORIES = ['All', 'Boosts', 'Coins', 'Cosmetics', 'Companions', 'Consumables']
const COLOR_MAP: Record<string, string> = {
  'neon-cyan': 'border-neon-cyan/40 text-neon-cyan',
  'neon-green': 'border-neon-green/40 text-neon-green',
  'neon-purple': 'border-neon-purple/40 text-neon-purple',
  'neon-pink': 'border-neon-pink/40 text-neon-pink',
  'yellow-400': 'border-yellow-400/40 text-yellow-400',
  'red-400': 'border-red-400/40 text-red-400',
}

export default function ShopClient({ initialCoins, userId }: { initialCoins: number; userId: string }) {
  const [coins, setCoins] = useState(initialCoins)
  const [gems] = useState(0)
  const [filter, setFilter] = useState('All')
  const [purchased, setPurchased] = useState<Set<string>>(new Set())
  const [loading, setLoading] = useState<string | null>(null)
  const [flash, setFlash] = useState<{ msg: string; ok: boolean } | null>(null)

  const visible = filter === 'All' ? SHOP_ITEMS : SHOP_ITEMS.filter(i => i.category === filter)

  async function buy(item: ShopItem) {
    if (loading) return
    if (item.price_coins > 0 && coins < item.price_coins) {
      setFlash({ msg: 'Not enough coins!', ok: false }); setTimeout(() => setFlash(null), 2000); return
    }
    if (item.price_gems > 0 && gems < item.price_gems) {
      setFlash({ msg: 'Not enough gems!', ok: false }); setTimeout(() => setFlash(null), 2000); return
    }

    setLoading(item.id)
    // Optimistic UI
    await new Promise(r => setTimeout(r, 600))
    if (item.price_coins > 0) setCoins(c => c - item.price_coins)
    setPurchased(s => new Set([...s, item.id]))
    setFlash({ msg: `${item.icon} ${item.name} purchased!`, ok: true })
    setTimeout(() => setFlash(null), 2500)
    if (item.category === 'Companions') {
      confetti({ particleCount: 60, spread: 70, origin: { y: 0.5 }, colors: ['#B026FF', '#00F6FF'] })
    }
    setLoading(null)
  }

  return (
    <div className="space-y-6">
      {/* Balance row */}
      <div className="flex gap-4 text-sm">
        <span className="text-neon-green font-bold">{coins.toLocaleString()} 🪙</span>
        <span className="text-slate-500">|</span>
        <span className="text-neon-cyan font-bold">{gems} 💎 gems</span>
        <span className="text-xs text-slate-600 self-center">(gems coming soon)</span>
      </div>

      {/* Flash message */}
      <AnimatePresence>
        {flash && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0 }}
            className={`text-sm font-display tracking-wider text-center py-2 rounded-lg ${flash.ok ? 'text-neon-green bg-neon-green/10' : 'text-red-400 bg-red-900/20'}`}
          >
            {flash.msg}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Category filter */}
      <div className="flex gap-2 flex-wrap">
        {CATEGORIES.map(c => (
          <button key={c} onClick={() => setFilter(c)}
            className={`px-3 py-1 rounded-lg text-xs font-display tracking-wider border transition-all
              ${filter === c ? 'border-neon-pink bg-neon-pink/10 text-neon-pink' : 'border-slate-700 text-slate-500 hover:border-slate-500'}`}>
            {c}
          </button>
        ))}
      </div>

      {/* Items grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
        {visible.map(item => {
          const isBought = purchased.has(item.id)
          const colorCls = COLOR_MAP[item.color] ?? 'border-slate-700 text-slate-300'
          return (
            <motion.div
              key={item.id}
              whileHover={{ scale: 1.02 }}
              className={`rounded-xl border bg-[#0a0813]/60 p-4 flex flex-col gap-2 transition-all ${isBought ? 'opacity-50 border-slate-800' : colorCls}`}
            >
              <div className="flex items-center gap-3">
                <span className="text-3xl">{item.icon}</span>
                <div>
                  <p className="text-sm font-display tracking-wider">{item.name}</p>
                  <p className="text-xs text-slate-500">{item.category}</p>
                </div>
              </div>
              <p className="text-xs text-slate-400 flex-1">{item.desc}</p>
              <div className="flex items-center justify-between mt-1">
                <span className="text-xs font-bold">
                  {item.price_coins > 0 ? <span className="text-neon-green">{item.price_coins.toLocaleString()} 🪙</span>
                    : <span className="text-neon-cyan">{item.price_gems} 💎</span>}
                </span>
                <motion.button
                  whileTap={{ scale: 0.95 }}
                  onClick={() => !isBought && buy(item)}
                  disabled={isBought || loading === item.id}
                  className={`text-xs font-display tracking-widest px-3 py-1.5 rounded-lg border transition-all
                    ${isBought ? 'border-slate-700 text-slate-600 cursor-default'
                      : `${colorCls} hover:bg-current/10 disabled:opacity-50`}`}
                >
                  {isBought ? 'OWNED' : loading === item.id ? '…' : 'BUY'}
                </motion.button>
              </div>
            </motion.div>
          )
        })}
      </div>
    </div>
  )
}
