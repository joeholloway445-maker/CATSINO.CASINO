export type GameMode = 'rpg' | 'action' | 'sim' | 'casino'

export interface Player {
  id: string
  username: string
  hope_companion_id: string
  current_mode: GameMode | null
  xp: number
  level: number
  created_at: string
}

export interface HopeMessage {
  role: 'hope' | 'player'
  content: string
  timestamp: Date
}

export interface GameState {
  scene: string
  mode: GameMode | null
  paused: boolean
}

export type SceneKey =
  | 'BootScene'
  | 'MainMenuScene'
  | 'ModeSelectorScene'
  | 'RPGScene'
  | 'BattleScene'
  | 'ActionScene'
  | 'SimScene'
  | 'CasinoScene'
  | 'SlotsScene'
  | 'BlackjackScene'
  | 'RouletteScene'
  | 'CrashScene'
  | 'DiceScene'
  | 'RacingScene'
  | 'SportsScene'
  | 'ArcadeScene'
