import Phaser from 'phaser'
import type { GameVariantConfig } from '@/lib/game/data/gameFactory'

export class ArcadeScene extends Phaser.Scene {
  private variant!: GameVariantConfig

  constructor() {
    super({ key: 'ArcadeScene' })
  }

  init(data: { variant?: GameVariantConfig }) {
    this.variant = data.variant ?? {
      id: 'arcade_default', name: 'Arcade Galaxy', category: 'arcade', scene: 'ArcadeScene',
      district: 'arcade_galaxy', primaryColor: 0x4ade80, accentColor: 0x86efac,
      description: '', minBet: 5, maxBet: 500, houseEdge: 0.04, volatility: 'low',
      ruleKey: 'tier1', unlockTier: 2,
    }
  }

  create() {
    const { width, height } = this.cameras.main
    const color = this.variant.primaryColor

    this.add.rectangle(width / 2, height / 2, width, height, 0x050510)

    this.add
      .text(width / 2, height * 0.25, this.variant.name, {
        fontFamily: 'monospace', fontSize: '28px',
        color: '#' + color.toString(16).padStart(6, '0'),
      })
      .setOrigin(0.5)

    this.add
      .text(width / 2, height * 0.42, 'ARCADE GAMES · Coming Soon', {
        fontFamily: 'monospace', fontSize: '16px', color: '#94a3b8',
      })
      .setOrigin(0.5)

    this.add
      .text(width / 2, height * 0.55, 'Skill-based mini-games, Keno,\nPlinko, Scratch Cards & more.', {
        fontFamily: 'monospace', fontSize: '13px', color: '#4b5563', align: 'center',
      })
      .setOrigin(0.5)

    // pixel star field
    for (let i = 0; i < 30; i++) {
      const star = this.add.text(
        Phaser.Math.Between(0, width),
        Phaser.Math.Between(height * 0.65, height * 0.9),
        '✦',
        { fontFamily: 'monospace', fontSize: `${Phaser.Math.Between(8, 18)}px`, color: '#' + color.toString(16).padStart(6, '0') },
      ).setAlpha(Math.random() * 0.6 + 0.1)
      this.tweens.add({ targets: star, alpha: 0, duration: Phaser.Math.Between(600, 1800), yoyo: true, repeat: -1 })
    }

    this.add
      .text(40, 36, '← CASINO', { fontFamily: 'monospace', fontSize: '13px', color: '#6366f1' })
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => this.scene.start('CasinoScene'))
  }
}
