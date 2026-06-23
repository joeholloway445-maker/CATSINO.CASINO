import Phaser from 'phaser'
import type { GameVariantConfig } from '@/lib/game/data/gameFactory'

export class RacingScene extends Phaser.Scene {
  private variant!: GameVariantConfig

  constructor() {
    super({ key: 'RacingScene' })
  }

  init(data: { variant?: GameVariantConfig }) {
    this.variant = data.variant ?? {
      id: 'racing_default', name: 'Neon Circuit', category: 'racing', scene: 'RacingScene',
      district: 'neon_alley', primaryColor: 0xf43f5e, accentColor: 0xfda4af,
      description: '', minBet: 10, maxBet: 5000, houseEdge: 0.05, volatility: 'medium',
      ruleKey: 'sprint', unlockTier: 1,
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
      .text(width / 2, height * 0.42, 'RACING · Coming Soon', {
        fontFamily: 'monospace', fontSize: '16px', color: '#94a3b8',
      })
      .setOrigin(0.5)

    this.add
      .text(width / 2, height * 0.55, 'Pick your faction racer.\nBet on the outcome. First across wins.', {
        fontFamily: 'monospace', fontSize: '13px', color: '#4b5563', align: 'center',
      })
      .setOrigin(0.5)

    // animated track lines
    for (let i = 0; i < 6; i++) {
      const line = this.add.rectangle(
        Phaser.Math.Between(-200, width + 200),
        height * 0.7 + i * 14,
        Phaser.Math.Between(60, 160), 3, color, 0.4,
      )
      this.tweens.add({
        targets: line, x: width + 300,
        duration: Phaser.Math.Between(1200, 2800),
        repeat: -1, ease: 'Linear',
        onRepeat: () => { line.x = -200 },
      })
    }

    this.add
      .text(40, 36, '← CASINO', { fontFamily: 'monospace', fontSize: '13px', color: '#6366f1' })
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => this.scene.start('CasinoScene'))
  }
}
