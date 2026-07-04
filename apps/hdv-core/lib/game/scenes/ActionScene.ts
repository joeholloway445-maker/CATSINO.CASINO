import Phaser from 'phaser'

export class ActionScene extends Phaser.Scene {
  private particles!: Phaser.GameObjects.Graphics[]

  constructor() {
    super({ key: 'ActionScene' })
  }

  create() {
    const { width, height } = this.cameras.main
    this.particles = []

    this.add.rectangle(width / 2, height / 2, width, height, 0x1a0a0a)

    this.add
      .text(width / 2, height * 0.2, 'FRACTURE', {
        fontFamily: 'monospace',
        fontSize: '32px',
        color: '#ef4444',
      })
      .setOrigin(0.5)

    this.add
      .text(width / 2, height * 0.35, 'Action Mode — Coming Soon', {
        fontFamily: 'monospace',
        fontSize: '18px',
        color: '#f87171',
      })
      .setOrigin(0.5)

    this.add
      .text(width / 2, height * 0.5,
        'Fast-paced combat in the shattered zones.\nSurvive. Dominate. Ascend.',
        {
          fontFamily: 'monospace',
          fontSize: '14px',
          color: '#fca5a5',
          align: 'center',
        })
      .setOrigin(0.5)

    // Animated particle dots for atmosphere
    for (let i = 0; i < 12; i++) {
      const dot = this.add.graphics()
      dot.fillStyle(0xef4444, 0.7)
      dot.fillCircle(0, 0, 3)
      dot.x = Phaser.Math.Between(0, width)
      dot.y = Phaser.Math.Between(0, height)
      this.particles.push(dot)

      this.tweens.add({
        targets: dot,
        x: Phaser.Math.Between(0, width),
        y: Phaser.Math.Between(0, height),
        duration: Phaser.Math.Between(2000, 5000),
        repeat: -1,
        yoyo: true,
        ease: 'Sine.easeInOut',
      })
    }

    this.add
      .text(40, 40, '← MODES', {
        fontFamily: 'monospace',
        fontSize: '14px',
        color: '#ef4444',
      })
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => this.scene.start('ModeSelectorScene'))
  }
}
