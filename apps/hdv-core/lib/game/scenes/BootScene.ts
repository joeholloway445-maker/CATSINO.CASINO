import Phaser from 'phaser'

export class BootScene extends Phaser.Scene {
  constructor() {
    super({ key: 'BootScene' })
  }

  preload() {
    // Progress bar
    const { width, height } = this.cameras.main

    const bar = this.add.graphics()
    const barBg = this.add.rectangle(width / 2, height / 2, 320, 20, 0x1a1a2e)
    barBg.setStrokeStyle(2, 0x7c3aed)

    this.load.on('progress', (value: number) => {
      bar.clear()
      bar.fillStyle(0x7c3aed)
      bar.fillRect(width / 2 - 156, height / 2 - 8, 312 * value, 16)
    })

    this.load.on('complete', () => bar.destroy())

    // Placeholder assets — swap with real sprites later
  }

  create() {
    this.scene.start('MainMenuScene')
  }
}
