import type { CurrencyDef } from '@/types/currencies'

export const CURRENCIES: CurrencyDef[] = [
  {
    id: 'coin',
    name: 'Coin',
    symbol: '◈',
    color: '#fbbf24',
    colorHex: 0xfbbf24,
    description: 'Universal currency. Purchased with real money and accepted everywhere.',
    earnedBy: 'Purchase with real currency',
    spentOn: 'Anything — cosmetics, items, exchange for Chip',
  },
  {
    id: 'chip',
    name: 'Chip',
    symbol: '⬡',
    color: '#a78bfa',
    colorHex: 0xa78bfa,
    description: 'Wagering and voting currency. Exchanged from Coin only.',
    earnedBy: 'Exchanged from Coin at 10:1 rate',
    spentOn: 'Mini-game wagering, storyline vote participation',
  },
  {
    id: 'fragments',
    name: 'Fragments',
    symbol: '◆',
    color: '#34d399',
    colorHex: 0x34d399,
    description: 'PvE reward currency for those who brave the spaces alone.',
    earnedBy: 'PvE encounters, space exploration, entity collection',
    spentOn: 'PvE items, entity boosts, map unlocks',
  },
  {
    id: 'tokens',
    name: 'Tokens',
    symbol: '◉',
    color: '#f87171',
    colorHex: 0xf87171,
    description: 'PvP reward currency for those who test themselves against others.',
    earnedBy: 'PvP victories, faction battles, seasonal rankings',
    spentOn: 'PvP items, faction war equipment, battle cosmetics',
  },
  {
    id: 'charges',
    name: 'Charges',
    symbol: '⚡',
    color: '#60a5fa',
    colorHex: 0x60a5fa,
    description: 'Rare energy currency for powering your companion deities.',
    earnedBy: 'Random drops throughout gameplay, rare encounters',
    spentOn: 'Boosting companion stats, unlocking deity abilities',
  },
  {
    id: 'renown',
    name: 'Renown',
    symbol: '✦',
    color: '#e879f9',
    colorHex: 0xe879f9,
    description: 'Your reputation and standing. Also the price of access beyond your Prestige.',
    earnedBy: 'All activity: exploration, combat, collecting',
    spentOn: 'Access to restricted zones, sacrifice for special access',
  },
]

export function getCurrencyById(id: string): CurrencyDef | undefined {
  return CURRENCIES.find((c) => c.id === id)
}

export const PRESTIGE_TITLES: Record<number, string> = {
  1: 'Initiate',
  2: 'Wanderer',
  3: 'Seeker',
  4: 'Adept',
  5: 'Artisan',
  6: 'Champion',
  7: 'Sovereign',
  8: 'Archon',
  9: 'Ascendant',
  10: 'Periliminal',
}
