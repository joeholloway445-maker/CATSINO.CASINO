export type GameDef = {
  slug: string
  name: string
  tagline: string
  emoji: string
  color: 'purple' | 'cyan' | 'green' | 'pink'
  playable: boolean
}

export const GAMES: GameDef[] = [
  {
    slug: 'purr-play-slots',
    name: 'Purr Play Slots',
    tagline: 'Classic 3-reel neon cat slots. Spin for Cat Chips.',
    emoji: '🎰',
    color: 'purple',
    playable: true,
  },
  {
    slug: 'black-cat-21',
    name: 'Black Cat 21',
    tagline: 'Blackjack with nine lives of luck.',
    emoji: '🃏',
    color: 'cyan',
    playable: true,
  },
  {
    slug: 'nine-lives-holdem',
    name: "9 Lives Hold 'Em",
    tagline: "Texas Hold 'Em vs the dealer — 9 lives per session.",
    emoji: '♠️',
    color: 'green',
    playable: true,
  },
  {
    slug: 'lucky-cat-jackpot',
    name: 'Lucky Cat Jackpot',
    tagline: 'Chase the golden paw jackpot.',
    emoji: '🐾',
    color: 'pink',
    playable: true,
  },
  {
    slug: 'catnip-cash',
    name: 'Catnip Cash',
    tagline: 'Bonus rounds packed with catnip rewards.',
    emoji: '🌿',
    color: 'green',
    playable: true,
  },
  {
    slug: 'whisker-wins',
    name: 'Whisker Wins',
    tagline: '5-card draw poker — Jacks or Better.',
    emoji: '🎴',
    color: 'cyan',
    playable: true,
  },
  {
    slug: 'feline-fortune',
    name: 'Feline Fortune',
    tagline: '9 mystic fortune cards — up to 10x jackpot.',
    emoji: '🔮',
    color: 'purple',
    playable: true,
  },
]

export const COLOR_CLASSES: Record<GameDef['color'], { text: string; border: string; glow: string }> = {
  purple: { text: 'text-neon-purple', border: 'border-neon-purple/50', glow: 'shadow-[0_0_20px_rgba(176,38,255,0.35)]' },
  cyan: { text: 'text-neon-cyan', border: 'border-neon-cyan/50', glow: 'shadow-[0_0_20px_rgba(0,246,255,0.35)]' },
  green: { text: 'text-neon-green', border: 'border-neon-green/50', glow: 'shadow-[0_0_20px_rgba(57,255,136,0.35)]' },
  pink: { text: 'text-neon-pink', border: 'border-neon-pink/50', glow: 'shadow-[0_0_20px_rgba(255,43,214,0.35)]' },
}
