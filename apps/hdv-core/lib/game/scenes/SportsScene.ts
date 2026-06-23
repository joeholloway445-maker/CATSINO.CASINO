import Phaser from 'phaser'
import type { GameVariantConfig } from '@/lib/game/data/gameFactory'

export class SportsScene extends Phaser.Scene {
  private variant!: GameVariantConfig

  constructor() {
    super({ key: 'SportsScene' })
  }

  init(data: { variant?: GameVariantConfig }) {
    this.variant = data.variant ?? {
      id: 'sports_default', name: 'Coliseum Match', category: 'sports', scene: 'SportsScene',
      district: 'cat_coliseum', primaryColor: 0xef4444, accentColor: 0xfca5a5,
      description: '', minBet: 10, maxBet: 5000, houseEdge: 0.04, volatility: 'medium',
      ruleKey: '1v1', unlockTier: 1,
    }
  }

  create() {
    const { width, height } = this.cameras.main
    const color = this.variant.primaryColor

    this.add.rectangle(width / 2, height / 2, width, height, 0x0a0505)

    this.add
      .text(width / 2, height * 0.25, this.variant.name, {
        fontFamily: 'monospace', fontSize: '28px',
        color: '#' + color.toString(16).padStart(6, '0'),
      })
      .setOrigin(0.5)

    this.add
      .text(width / 2, height * 0.42, 'SPORTS BETTING · Coming Soon', {
        fontFamily: 'monospace', fontSize: '16px', color: '#94a3b8',
      })
      .setOrigin(0.5)

    this.add
      .text(width / 2, height * 0.55, 'Wager on faction matches.\nFight outcomes. Champion leagues.', {
        fontFamily: 'monospace', fontSize: '13px', color: '#4b5563', align: 'center',
      })
      .setOrigin(0.5)

    const gfx = this.add.graphics()
    gfx.fillStyle(color, 0.15)
    gfx.fillCircle(width / 2, height * 0.72, 60)
    gfx.lineStyle(2, color, 0.5)
    gfx.strokeCircle(width / 2, height * 0.72, 60)
    this.tweens.add({ targets: gfx, scaleX: 1.1, scaleY: 1.1, duration: 1000, yoyo: true, repeat: -1 })

    this.add
      .text(40, 36, '← CASINO', { fontFamily: 'monospace', fontSize: '13px', color: '#6366f1' })
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => this.scene.start('CasinoScene'))
  }
}
