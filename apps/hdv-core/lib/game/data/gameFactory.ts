export type GameCategory = 'slots' | 'blackjack' | 'roulette' | 'crash' | 'dice' | 'racing' | 'sports' | 'arcade'
export type District = 'paw_vegas' | 'neon_alley' | 'cat_coliseum' | 'arcade_galaxy' | 'cat_forest'
export type Volatility = 'low' | 'medium' | 'high'

export interface GameVariantConfig {
  id: string
  name: string
  category: GameCategory
  scene: string
  district: District
  primaryColor: number
  accentColor: number
  symbols?: string[]
  description: string
  minBet: number
  maxBet: number
  houseEdge: number
  volatility: Volatility
  ruleKey: string
  unlockTier: number
  hot?: boolean
}

// ─── Skin definitions ───────────────────────────────────────────────────────

const SKINS = {
  sovereign:    { primaryColor: 0x6366f1, accentColor: 0xc4b5fd, label: 'Sovereign' },
  veiled:       { primaryColor: 0x22c55e, accentColor: 0x86efac, label: 'Veiled'    },
  wildlands:    { primaryColor: 0xf59e0b, accentColor: 0xfde68a, label: 'Wildlands' },
  factionless:  { primaryColor: 0x94a3b8, accentColor: 0xcbd5e1, label: 'Factionless' },
  hope:         { primaryColor: 0xa855f7, accentColor: 0xf0abfc, label: 'HOPE'      },
  extraliminal: { primaryColor: 0x06b6d4, accentColor: 0xa5f3fc, label: 'Extraliminal' },
  neon:         { primaryColor: 0xf43f5e, accentColor: 0xfda4af, label: 'Neon'      },
  glacial:      { primaryColor: 0x38bdf8, accentColor: 0xbae6fd, label: 'Glacial'   },
  volcanic:     { primaryColor: 0xef4444, accentColor: 0xfca5a5, label: 'Volcanic'  },
  void_:        { primaryColor: 0x312e81, accentColor: 0x6d28d9, label: 'Void'      },
} as const

// ─── Symbol sets ─────────────────────────────────────────────────────────────

const SYMBOL_SETS: Record<string, string[]> = {
  sovereign:    ['👑', '⚔', '🏰', '⚜', '🛡', '💎', '✧', '❈', '◆'],
  veiled:       ['〰', '◉', '🌊', '👁', '✦', '🔮', '✧', '❈', '◆'],
  wildlands:    ['✿', '✦', '🌿', '🐾', '⚡', '🌙', '✧', '❈', '◆'],
  hope:         ['✧', '✦', '☀', '◎', '❋', '⭐', '★', '❈', '◆'],
  extraliminal: ['◈', '⊕', '⟐', '⌘', '⊛', '⟡', '✧', '❈', '◆'],
  neon:         ['7', 'BAR', '🍒', '🔔', '★', '💠', '✧', '❈', '◆'],
  classic:      ['🍒', '🍋', '🍊', '🍇', '🔔', 'BAR', '7', '❈', '◆'],
  crystal:      ['💎', '💠', '🔷', '⬡', '◈', '⟐', '✧', '❈', '◆'],
  battle:       ['⚔', '🛡', '🏹', '🗡', '⚡', '💥', '✧', '❈', '◆'],
}

// ─── SLOTS — 60 variants ─────────────────────────────────────────────────────

const SLOT_THEMES = [
  { key: 'sovereign',    name: 'Sovereign Vault',     skin: SKINS.sovereign,    symbols: SYMBOL_SETS.sovereign,    district: 'paw_vegas' as District },
  { key: 'veiled',       name: 'Veiled Tides',        skin: SKINS.veiled,       symbols: SYMBOL_SETS.veiled,       district: 'paw_vegas' as District },
  { key: 'wildlands',    name: 'Wildlands Fortune',   skin: SKINS.wildlands,    symbols: SYMBOL_SETS.wildlands,    district: 'paw_vegas' as District },
  { key: 'hope',         name: 'HOPE Jackpot',        skin: SKINS.hope,         symbols: SYMBOL_SETS.hope,         district: 'paw_vegas' as District },
  { key: 'extraliminal', name: 'Extraliminal Reels',  skin: SKINS.extraliminal, symbols: SYMBOL_SETS.extraliminal, district: 'arcade_galaxy' as District },
  { key: 'classic',      name: 'Paws Vegas Classic',  skin: SKINS.neon,         symbols: SYMBOL_SETS.classic,      district: 'paw_vegas' as District },
  { key: 'crystal',      name: 'Crystal Cascade',     skin: SKINS.glacial,      symbols: SYMBOL_SETS.crystal,      district: 'paw_vegas' as District },
  { key: 'battle',       name: 'Fracture Slots',      skin: SKINS.volcanic,     symbols: SYMBOL_SETS.battle,       district: 'cat_coliseum' as District },
  { key: 'void',         name: 'Void Gate',           skin: SKINS.void_,        symbols: SYMBOL_SETS.sovereign,    district: 'arcade_galaxy' as District },
  { key: 'neon',         name: 'Neon Strip',          skin: SKINS.neon,         symbols: SYMBOL_SETS.neon,         district: 'neon_alley' as District },
]
const SLOT_RULES = [
  { ruleKey: '3line',   label: '3-Line',   minBet: 5,  maxBet: 500,  houseEdge: 0.05, volatility: 'low'    as Volatility },
  { ruleKey: '5line',   label: '5-Line',   minBet: 10, maxBet: 1000, houseEdge: 0.04, volatility: 'medium' as Volatility },
  { ruleKey: '9line',   label: '9-Line',   minBet: 20, maxBet: 2000, houseEdge: 0.04, volatility: 'medium' as Volatility },
  { ruleKey: '243way',  label: '243-Way',  minBet: 30, maxBet: 3000, houseEdge: 0.03, volatility: 'high'   as Volatility },
  { ruleKey: '1024way', label: '1024-Way', minBet: 50, maxBet: 5000, houseEdge: 0.03, volatility: 'high'   as Volatility },
  { ruleKey: 'turbo',   label: 'Turbo',    minBet: 10, maxBet: 1000, houseEdge: 0.05, volatility: 'high'   as Volatility },
]

function buildSlots(): GameVariantConfig[] {
  const out: GameVariantConfig[] = []
  SLOT_THEMES.forEach((theme) => {
    SLOT_RULES.forEach((rule, ri) => {
      out.push({
        id: `slots_${theme.key}_${rule.ruleKey}`,
        name: `${theme.name} — ${rule.label}`,
        category: 'slots',
        scene: 'SlotsScene',
        district: theme.district,
        primaryColor: theme.skin.primaryColor,
        accentColor: theme.skin.accentColor,
        symbols: theme.symbols,
        description: `${theme.name} slot machine with ${rule.label} paylines.`,
        minBet: rule.minBet,
        maxBet: rule.maxBet,
        houseEdge: rule.houseEdge,
        volatility: rule.volatility,
        ruleKey: rule.ruleKey,
        unlockTier: Math.min(5, Math.floor(ri / 2) + 1),
        hot: theme.key === 'hope' && rule.ruleKey === '243way',
      })
    })
  })
  return out
}

// ─── BLACKJACK — 24 variants ──────────────────────────────────────────────────

const BJ_SKINS = [
  { key: 'sovereign',   name: 'Sovereign 21',       skin: SKINS.sovereign,    district: 'paw_vegas'    as District },
  { key: 'veiled',      name: 'Veiled Blackjack',   skin: SKINS.veiled,       district: 'paw_vegas'    as District },
  { key: 'wildlands',   name: 'Wildlands 21',       skin: SKINS.wildlands,    district: 'cat_coliseum' as District },
  { key: 'hope',        name: 'HOPE Blackjack',     skin: SKINS.hope,         district: 'paw_vegas'    as District },
]
const BJ_RULES = [
  { ruleKey: 'classic',     label: 'Classic',     minBet: 10, maxBet: 2000, houseEdge: 0.005, volatility: 'low'    as Volatility },
  { ruleKey: 'surrender',   label: 'Surrender',   minBet: 10, maxBet: 2000, houseEdge: 0.004, volatility: 'low'    as Volatility },
  { ruleKey: 'progressive', label: 'Progressive', minBet: 20, maxBet: 5000, houseEdge: 0.008, volatility: 'high'   as Volatility },
  { ruleKey: 'single_deck', label: 'Single Deck', minBet: 25, maxBet: 1000, houseEdge: 0.003, volatility: 'medium' as Volatility },
  { ruleKey: 'multi_deck',  label: '6-Deck',      minBet: 5,  maxBet: 5000, houseEdge: 0.006, volatility: 'low'    as Volatility },
  { ruleKey: 'vip',         label: 'VIP Table',   minBet: 100, maxBet: 50000, houseEdge: 0.005, volatility: 'medium' as Volatility },
]

function buildBlackjack(): GameVariantConfig[] {
  const out: GameVariantConfig[] = []
  BJ_SKINS.forEach((s) => {
    BJ_RULES.forEach((r, ri) => {
      out.push({
        id: `bj_${s.key}_${r.ruleKey}`,
        name: `${s.name} — ${r.label}`,
        category: 'blackjack',
        scene: 'BlackjackScene',
        district: s.district,
        primaryColor: s.skin.primaryColor,
        accentColor: s.skin.accentColor,
        description: `${r.label} blackjack with ${s.name} faction skin.`,
        minBet: r.minBet,
        maxBet: r.maxBet,
        houseEdge: r.houseEdge,
        volatility: r.volatility,
        ruleKey: r.ruleKey,
        unlockTier: Math.min(5, ri + 1),
        hot: s.key === 'hope' && r.ruleKey === 'progressive',
      })
    })
  })
  return out
}

// ─── ROULETTE — 12 variants ───────────────────────────────────────────────────

const ROULETTE_SKINS = [
  { key: 'sovereign',   name: 'Crown Roulette',      skin: SKINS.sovereign,    district: 'paw_vegas' as District },
  { key: 'veiled',      name: 'Tide Wheel',          skin: SKINS.veiled,       district: 'paw_vegas' as District },
  { key: 'wildlands',   name: 'Wild Spin',           skin: SKINS.wildlands,    district: 'cat_forest' as District },
  { key: 'hope',        name: 'Fate Wheel',          skin: SKINS.hope,         district: 'paw_vegas' as District },
]
const ROULETTE_RULES = [
  { ruleKey: 'european', label: 'European',  minBet: 5, maxBet: 5000, houseEdge: 0.027, volatility: 'medium' as Volatility },
  { ruleKey: 'american', label: 'American',  minBet: 5, maxBet: 5000, houseEdge: 0.053, volatility: 'medium' as Volatility },
  { ruleKey: 'hdv',      label: 'HDV Custom',minBet: 10, maxBet: 10000, houseEdge: 0.02, volatility: 'high'  as Volatility },
]

function buildRoulette(): GameVariantConfig[] {
  const out: GameVariantConfig[] = []
  ROULETTE_SKINS.forEach((s) => {
    ROULETTE_RULES.forEach((r, ri) => {
      out.push({
        id: `roulette_${s.key}_${r.ruleKey}`,
        name: `${s.name} — ${r.label}`,
        category: 'roulette',
        scene: 'RouletteScene',
        district: s.district,
        primaryColor: s.skin.primaryColor,
        accentColor: s.skin.accentColor,
        description: `${r.label} roulette with ${s.name} faction skin.`,
        minBet: r.minBet,
        maxBet: r.maxBet,
        houseEdge: r.houseEdge,
        volatility: r.volatility,
        ruleKey: r.ruleKey,
        unlockTier: ri + 1,
        hot: s.key === 'hope' && r.ruleKey === 'hdv',
      })
    })
  })
  return out
}

// ─── CRASH — 20 variants ──────────────────────────────────────────────────────

const CRASH_THEMES = [
  { key: 'ascension',    name: 'ASCENSION',          skin: SKINS.hope,         district: 'arcade_galaxy' as District },
  { key: 'sovereign',    name: 'Crown Crash',         skin: SKINS.sovereign,    district: 'paw_vegas'    as District },
  { key: 'wildfire',     name: 'Wildfire',            skin: SKINS.volcanic,     district: 'cat_coliseum' as District },
  { key: 'glacial',      name: 'Glacial Ascent',      skin: SKINS.glacial,      district: 'arcade_galaxy' as District },
  { key: 'void',         name: 'Void Collapse',       skin: SKINS.void_,        district: 'arcade_galaxy' as District },
]
const CRASH_RULES = [
  { ruleKey: 'standard', label: 'Standard', minBet: 10, maxBet: 10000, houseEdge: 0.01, volatility: 'high'   as Volatility },
  { ruleKey: 'turbo',    label: 'Turbo',    minBet: 10, maxBet: 10000, houseEdge: 0.01, volatility: 'high'   as Volatility },
  { ruleKey: 'safe',     label: 'Safe Mode',minBet: 5,  maxBet: 5000,  houseEdge: 0.01, volatility: 'medium' as Volatility },
  { ruleKey: 'extreme',  label: 'Extreme',  minBet: 50, maxBet: 50000, houseEdge: 0.01, volatility: 'high'   as Volatility },
]

function buildCrash(): GameVariantConfig[] {
  const out: GameVariantConfig[] = []
  CRASH_THEMES.forEach((t) => {
    CRASH_RULES.forEach((r, ri) => {
      out.push({
        id: `crash_${t.key}_${r.ruleKey}`,
        name: `${t.name} — ${r.label}`,
        category: 'crash',
        scene: 'CrashScene',
        district: t.district,
        primaryColor: t.skin.primaryColor,
        accentColor: t.skin.accentColor,
        description: `${r.label} crash game. Bet, watch the multiplier rise, cash out before it crashes!`,
        minBet: r.minBet,
        maxBet: r.maxBet,
        houseEdge: r.houseEdge,
        volatility: r.volatility,
        ruleKey: r.ruleKey,
        unlockTier: Math.min(5, ri + 1),
        hot: t.key === 'ascension' && r.ruleKey === 'standard',
      })
    })
  })
  return out
}

// ─── DICE — 20 variants ───────────────────────────────────────────────────────

const DICE_THEMES = [
  { key: 'fracture',  name: 'Fracture Dice',   skin: SKINS.volcanic,    district: 'cat_coliseum' as District },
  { key: 'sovereign', name: 'Crown Dice',       skin: SKINS.sovereign,   district: 'paw_vegas'    as District },
  { key: 'veiled',    name: 'Tide Dice',        skin: SKINS.veiled,      district: 'paw_vegas'    as District },
  { key: 'wild',      name: 'Wild Bones',       skin: SKINS.wildlands,   district: 'cat_forest'   as District },
  { key: 'void',      name: 'Void Dice',        skin: SKINS.void_,       district: 'arcade_galaxy' as District },
]
const DICE_RULES = [
  { ruleKey: 'classic',      label: 'Classic',       minBet: 5,  maxBet: 2000,  houseEdge: 0.014, volatility: 'medium' as Volatility },
  { ruleKey: 'triple',       label: 'Triple Dice',   minBet: 10, maxBet: 3000,  houseEdge: 0.016, volatility: 'high'   as Volatility },
  { ruleKey: 'faction_bonus',label: 'Faction Bonus', minBet: 10, maxBet: 2000,  houseEdge: 0.012, volatility: 'medium' as Volatility },
  { ruleKey: 'high_stakes',  label: 'High Stakes',   minBet: 50, maxBet: 10000, houseEdge: 0.015, volatility: 'high'   as Volatility },
]

function buildDice(): GameVariantConfig[] {
  const out: GameVariantConfig[] = []
  DICE_THEMES.forEach((t) => {
    DICE_RULES.forEach((r, ri) => {
      out.push({
        id: `dice_${t.key}_${r.ruleKey}`,
        name: `${t.name} — ${r.label}`,
        category: 'dice',
        scene: 'DiceScene',
        district: t.district,
        primaryColor: t.skin.primaryColor,
        accentColor: t.skin.accentColor,
        description: `${r.label} dice game with ${t.name} skin.`,
        minBet: r.minBet,
        maxBet: r.maxBet,
        houseEdge: r.houseEdge,
        volatility: r.volatility,
        ruleKey: r.ruleKey,
        unlockTier: Math.min(5, ri + 2),
        hot: t.key === 'fracture' && r.ruleKey === 'triple',
      })
    })
  })
  return out
}

// ─── RACING — 30 variants ─────────────────────────────────────────────────────

const RACING_TRACKS = [
  { key: 'neon_circuit', name: 'Neon Circuit',       skin: SKINS.neon,         district: 'neon_alley'   as District },
  { key: 'sovereign_rd', name: 'Crown Royal Road',   skin: SKINS.sovereign,    district: 'neon_alley'   as District },
  { key: 'wildland_trail',name:'Wildlands Trail',    skin: SKINS.wildlands,    district: 'cat_forest'   as District },
  { key: 'void_drift',   name: 'Void Drift',         skin: SKINS.void_,        district: 'neon_alley'   as District },
  { key: 'glacier_run',  name: 'Glacial Run',        skin: SKINS.glacial,      district: 'neon_alley'   as District },
]
const RACING_TYPES = [
  { ruleKey: 'sprint',     label: 'Sprint',       minBet: 10, maxBet: 5000,  houseEdge: 0.05, volatility: 'medium' as Volatility },
  { ruleKey: 'endurance',  label: 'Endurance',    minBet: 20, maxBet: 10000, houseEdge: 0.04, volatility: 'high'   as Volatility },
  { ruleKey: 'elimination',label: 'Elimination',  minBet: 15, maxBet: 7500,  houseEdge: 0.06, volatility: 'high'   as Volatility },
  { ruleKey: 'league',     label: 'League',       minBet: 25, maxBet: 25000, houseEdge: 0.04, volatility: 'low'    as Volatility },
  { ruleKey: 'faction',    label: 'Faction War',  minBet: 10, maxBet: 5000,  houseEdge: 0.05, volatility: 'medium' as Volatility },
  { ruleKey: 'grand_prix', label: 'Grand Prix',   minBet: 50, maxBet: 50000, houseEdge: 0.03, volatility: 'high'   as Volatility },
]

function buildRacing(): GameVariantConfig[] {
  const out: GameVariantConfig[] = []
  RACING_TRACKS.forEach((t) => {
    RACING_TYPES.forEach((r, ri) => {
      out.push({
        id: `racing_${t.key}_${r.ruleKey}`,
        name: `${t.name} — ${r.label}`,
        category: 'racing',
        scene: 'RacingScene',
        district: t.district,
        primaryColor: t.skin.primaryColor,
        accentColor: t.skin.accentColor,
        description: `${r.label} race on ${t.name}. Pick your faction racer and bet on the outcome.`,
        minBet: r.minBet,
        maxBet: r.maxBet,
        houseEdge: r.houseEdge,
        volatility: r.volatility,
        ruleKey: r.ruleKey,
        unlockTier: Math.min(5, Math.ceil((ri + 1) / 2)),
        hot: t.key === 'neon_circuit' && r.ruleKey === 'grand_prix',
      })
    })
  })
  return out
}

// ─── SPORTS — 20 variants ─────────────────────────────────────────────────────

const SPORTS_TYPES = [
  { key: 'coliseum', name: 'Coliseum Match', skin: SKINS.volcanic,  district: 'cat_coliseum' as District },
  { key: 'arena',    name: 'Arena Battle',   skin: SKINS.sovereign, district: 'cat_coliseum' as District },
  { key: 'trials',   name: 'Wildlands Trial',skin: SKINS.wildlands, district: 'cat_forest'   as District },
  { key: 'summit',   name: 'Summit Duel',    skin: SKINS.glacial,   district: 'cat_coliseum' as District },
]
const SPORTS_FORMATS = [
  { ruleKey: '1v1',      label: '1v1',          minBet: 10, maxBet: 5000,  houseEdge: 0.04, volatility: 'medium' as Volatility },
  { ruleKey: 'tournament',label:'Tournament',   minBet: 25, maxBet: 25000, houseEdge: 0.05, volatility: 'high'   as Volatility },
  { ruleKey: 'handicap', label: 'Handicap',     minBet: 10, maxBet: 10000, houseEdge: 0.045,volatility: 'medium' as Volatility },
  { ruleKey: 'spread',   label: 'Spread',       minBet: 10, maxBet: 10000, houseEdge: 0.04, volatility: 'medium' as Volatility },
  { ruleKey: 'parlay',   label: 'Parlay',       minBet: 5,  maxBet: 2000,  houseEdge: 0.06, volatility: 'high'   as Volatility },
]

function buildSports(): GameVariantConfig[] {
  const out: GameVariantConfig[] = []
  SPORTS_TYPES.forEach((s) => {
    SPORTS_FORMATS.forEach((f, fi) => {
      out.push({
        id: `sports_${s.key}_${f.ruleKey}`,
        name: `${s.name} — ${f.label}`,
        category: 'sports',
        scene: 'SportsScene',
        district: s.district,
        primaryColor: s.skin.primaryColor,
        accentColor: s.skin.accentColor,
        description: `${f.label} betting on ${s.name} faction matches.`,
        minBet: f.minBet,
        maxBet: f.maxBet,
        houseEdge: f.houseEdge,
        volatility: f.volatility,
        ruleKey: f.ruleKey,
        unlockTier: Math.min(5, fi + 1),
        hot: s.key === 'coliseum' && f.ruleKey === 'tournament',
      })
    })
  })
  return out
}

// ─── ARCADE — 20 variants ─────────────────────────────────────────────────────

const ARCADE_GAMES = [
  { key: 'entity_draft', name: 'Entity Draft',    skin: SKINS.hope,        district: 'arcade_galaxy' as District },
  { key: 'blueprint',    name: 'Blueprint Scratch',skin: SKINS.extraliminal,district: 'arcade_galaxy' as District },
  { key: 'keno',         name: 'Faction Keno',    skin: SKINS.veiled,      district: 'arcade_galaxy' as District },
  { key: 'mines',        name: 'Void Mines',      skin: SKINS.void_,       district: 'arcade_galaxy' as District },
  { key: 'plinko',       name: 'HOPE Plinko',     skin: SKINS.hope,        district: 'arcade_galaxy' as District },
]
const ARCADE_TIERS = [
  { ruleKey: 'tier1', label: 'Tier I',  minBet: 5,  maxBet: 500,   houseEdge: 0.04, volatility: 'low'    as Volatility },
  { ruleKey: 'tier2', label: 'Tier II', minBet: 10, maxBet: 1000,  houseEdge: 0.04, volatility: 'medium' as Volatility },
  { ruleKey: 'tier3', label: 'Tier III',minBet: 25, maxBet: 5000,  houseEdge: 0.035,volatility: 'medium' as Volatility },
  { ruleKey: 'tier4', label: 'Tier IV', minBet: 50, maxBet: 10000, houseEdge: 0.03, volatility: 'high'   as Volatility },
]

function buildArcade(): GameVariantConfig[] {
  const out: GameVariantConfig[] = []
  ARCADE_GAMES.forEach((g) => {
    ARCADE_TIERS.forEach((t, ti) => {
      out.push({
        id: `arcade_${g.key}_${t.ruleKey}`,
        name: `${g.name} — ${t.label}`,
        category: 'arcade',
        scene: 'ArcadeScene',
        district: g.district,
        primaryColor: g.skin.primaryColor,
        accentColor: g.skin.accentColor,
        description: `${g.name} at ${t.label} stakes. Arcade-style game with HDV faction twist.`,
        minBet: t.minBet,
        maxBet: t.maxBet,
        houseEdge: t.houseEdge,
        volatility: t.volatility,
        ruleKey: t.ruleKey,
        unlockTier: ti + 2,
        hot: g.key === 'plinko' && t.ruleKey === 'tier2',
      })
    })
  })
  return out
}

// ─── Master catalogue ─────────────────────────────────────────────────────────

export const ALL_GAMES: GameVariantConfig[] = [
  ...buildSlots(),
  ...buildBlackjack(),
  ...buildRoulette(),
  ...buildCrash(),
  ...buildDice(),
  ...buildRacing(),
  ...buildSports(),
  ...buildArcade(),
]

export function getGamesByCategory(category: GameCategory): GameVariantConfig[] {
  return ALL_GAMES.filter((g) => g.category === category)
}

export function getGamesByDistrict(district: District): GameVariantConfig[] {
  return ALL_GAMES.filter((g) => g.district === district)
}

export function getHotGames(): GameVariantConfig[] {
  return ALL_GAMES.filter((g) => g.hot)
}

export function getGameById(id: string): GameVariantConfig | undefined {
  return ALL_GAMES.find((g) => g.id === id)
}

export const GAME_CATALOGUE_SIZE = ALL_GAMES.length
