export type CurrencyId = 'coin' | 'chip' | 'fragments' | 'tokens' | 'charges' | 'renown'

export interface CurrencyDef {
  id: CurrencyId
  name: string
  symbol: string
  color: string           // CSS
  colorHex: number        // Phaser
  description: string
  earnedBy: string
  spentOn: string
}

export interface PlayerCurrencies {
  user_id: string
  coin: number
  chip: number
  fragments: number
  tokens: number
  charges: number
  renown: number
  updated_at: string
}

export interface Prestige {
  level: number
  title: string
  xpRequired: number
}
