import Phaser from 'phaser'

export class MainMenuScene extends Phaser.Scene {
  constructor() {
    super({ key: 'MainMenuScene' })
  }

  create() {
    const { width, height } = this.cameras.main

    // Background gradient via rect + alpha
    this.add.rectangle(width / 2, height / 2, width, height, 0x0f0f1a)

    // Grid lines for cyberpunk feel
    const grid = this.add.graphics()
    grid.lineStyle(1, 0x1a1a3e, 0.4)
    for (let x = 0; x < width; x += 40) {
      grid.lineBetween(x, 0, x, height)
    }
    for (let y = 0; y < height; y += 40) {
      grid.lineBetween(0, y, width, y)
    }

    // Title
    this.add
      .text(width / 2, height * 0.3, 'THE HDV CORE', {
        fontFamily: 'monospace',
        fontSize: '42px',
        color: '#a855f7',
        stroke: '#7c3aed',
        strokeThickness: 4,
      })
      .setOrigin(0.5)

    this.add
      .text(width / 2, height * 0.42, 'HOPE · DREAM · VISION', {
        fontFamily: 'monospace',
        fontSize: '16px',
        color: '#6366f1',
        letterSpacing: 6,
      })
      .setOrigin(0.5)

    // Play button
    const btn = this.add
      .text(width / 2, height * 0.62, '[ ENTER ]', {
        fontFamily: 'monospace',
        fontSize: '28px',
        color: '#e2e8f0',
        backgroundColor: '#7c3aed',
        padding: { x: 24, y: 12 },
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true })

    btn.on('pointerover', () => btn.setStyle({ color: '#a855f7' }))
    btn.on('pointerout', () => btn.setStyle({ color: '#e2e8f0' }))
    btn.on('pointerdown', () => this.scene.start('ModeSelectorScene'))

    // Pulse animation on title
    this.tweens.add({
      targets: btn,
      alpha: 0.7,
      duration: 900,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut',
    })

    // Version
    this.add
      .text(width - 12, height - 12, 'v0.1.0-alpha', {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: '#4a4a6a',
      })
      .setOrigin(1, 1)
  }
}
