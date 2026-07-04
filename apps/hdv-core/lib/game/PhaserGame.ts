import Phaser, { type Types } from 'phaser'
import { BootScene } from './scenes/BootScene'
import { MainMenuScene } from './scenes/MainMenuScene'
import { ModeSelectorScene } from './scenes/ModeSelectorScene'
import { RPGScene } from './scenes/RPGScene'
import { BattleScene } from './scenes/BattleScene'
import { ActionScene } from './scenes/ActionScene'
import { SimScene } from './scenes/SimScene'
import { ExtraliminalScene } from './scenes/ExtraliminalScene'
import { CasinoScene } from './scenes/CasinoScene'
import { SlotsScene } from './scenes/SlotsScene'
import { BlackjackScene } from './scenes/BlackjackScene'
import { RouletteScene } from './scenes/RouletteScene'
import { CrashScene } from './scenes/CrashScene'
import { DiceScene } from './scenes/DiceScene'
import { RacingScene } from './scenes/RacingScene'
import { SportsScene } from './scenes/SportsScene'
import { ArcadeScene } from './scenes/ArcadeScene'

export function createGameConfig(parent: HTMLElement): Types.Core.GameConfig {
  return {
    type: Phaser.AUTO,
    parent,
    width: '100%',
    height: '100%',
    backgroundColor: '#0f0f1a',
    scene: [
      BootScene,
      MainMenuScene,
      ModeSelectorScene,
      // Core game modes
      RPGScene,
      BattleScene,
      ActionScene,
      SimScene,
      ExtraliminalScene,
      // Casino (Paws Vegas) — hub + game engines
      CasinoScene,
      SlotsScene,
      BlackjackScene,
      RouletteScene,
      CrashScene,
      DiceScene,
      RacingScene,
      SportsScene,
      ArcadeScene,
    ],
    scale: {
      mode: Phaser.Scale.RESIZE,
      autoCenter: Phaser.Scale.CENTER_BOTH,
    },
    physics: {
      default: 'arcade',
      arcade: { debug: false },
    },
  }
}
