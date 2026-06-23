import Phaser from 'phaser'

export class SimScene extends Phaser.Scene {
  private buildingPulse!: Phaser.GameObjects.Graphics

  constructor() {
    super({ key: 'SimScene' })
  }

  create() {
    const { width, height } = this.cameras.main

    this.add.rectangle(width / 2, height / 2, width, height, 0x0a0f1a)

    this.add
      .text(width / 2, height * 0.2, 'DOMINION', {
        fontFamily: 'monospace',
        fontSize: '32px',
        color: '#3b82f6',
      })
      .setOrigin(0.5)

    this.add
      .text(width / 2, height * 0.35, 'Simulation Mode — Coming Soon', {
        fontFamily: 'monospace',
        fontSize: '18px',
        color: '#60a5fa',
      })
      .setOrigin(0.5)

    this.add
      .text(width / 2, height * 0.5,
        'Build your empire. Manage resources.\nLet HOPE optimize your strategy.',
        {
          fontFamily: 'monospace',
          fontSize: '14px',
          color: '#93c5fd',
          align: 'center',
        })
      .setOrigin(0.5)

    // Simple city silhouette sketch
    this.buildingPulse = this.add.graphics()
    this.drawCityline(width, height)

    this.add
      .text(40, 40, '← MODES', {
        fontFamily: 'monospace',
        fontSize: '14px',
        color: '#3b82f6',
      })
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => this.scene.start('ModeSelectorScene'))
  }

  private drawCityline(width: number, height: number) {
    const g = this.buildingPulse
    g.fillStyle(0x1e3a5f, 0.6)

    const buildings = [
      [50, 80], [120, 120], [200, 60], [280, 100], [360, 70],
      [440, 110], [510, 50], [580, 90], [650, 80], [720, 60],
    ]

    buildings.forEach(([bx, bh]) => {
      g.fillRect(bx, height - bh - 40, 50, bh)
    })

    // Window lights
    g.fillStyle(0x60a5fa, 0.8)
    buildings.forEach(([bx, bh]) => {
      for (let wy = height - bh - 30; wy < height - 50; wy += 16) {
        for (let wx = bx + 8; wx < bx + 44; wx += 16) {
          if (Math.random() > 0.3) g.fillRect(wx, wy, 6, 8)
        }
      }
    })
  }
}
