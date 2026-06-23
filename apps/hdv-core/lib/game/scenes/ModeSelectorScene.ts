import Phaser from 'phaser'
import type { GameMode } from '@/types/game'

interface ModeCard {
  x: number
  label: string
  sub: string
  mode: GameMode
  scene: string
  color: number
}

export class ModeSelectorScene extends Phaser.Scene {
  constructor() {
    super({ key: 'ModeSelectorScene' })
  }

  create() {
    const { width, height } = this.cameras.main

    this.add.rectangle(width / 2, height / 2, width, height, 0x0f0f1a)

    this.add
      .text(width / 2, height * 0.12, 'SELECT YOUR PATH', {
        fontFamily: 'monospace',
        fontSize: '24px',
        color: '#a855f7',
        letterSpacing: 4,
      })
      .setOrigin(0.5)

    const modes: ModeCard[] = [
      { x: width * 0.15, label: 'CHRONICLES', sub: 'RPG · Story · World',    mode: 'rpg',    scene: 'RPGScene',    color: 0x22c55e },
      { x: width * 0.38, label: 'FRACTURE',   sub: 'Action · Combat · Speed', mode: 'action', scene: 'ActionScene', color: 0xef4444 },
      { x: width * 0.62, label: 'DOMINION',   sub: 'Sim · Build · Empire',   mode: 'sim',    scene: 'SimScene',    color: 0x3b82f6 },
      { x: width * 0.85, label: 'PAWS VEGAS', sub: 'Casino · 206+ Games',    mode: 'casino', scene: 'CasinoScene', color: 0xf59e0b },
    ]

    modes.forEach(({ x, label, sub, scene, color }) => {
      const card = this.add.container(x, height * 0.5)

      const bg = this.add.rectangle(0, 0, 200, 260, 0x1a1a2e)
      bg.setStrokeStyle(2, color, 0.6)

      const accent = this.add.rectangle(0, -100, 200, 4, color)

      const title = this.add.text(0, -60, label, {
        fontFamily: 'monospace',
        fontSize: '18px',
        color: '#e2e8f0',
      }).setOrigin(0.5)

      const subtitle = this.add.text(0, -30, sub, {
        fontFamily: 'monospace',
        fontSize: '11px',
        color: '#6366f1',
      }).setOrigin(0.5)

      const enterBtn = this.add.text(0, 70, '[ PLAY ]', {
        fontFamily: 'monospace',
        fontSize: '14px',
        color: '#e2e8f0',
        backgroundColor: '#' + color.toString(16).padStart(6, '0'),
        padding: { x: 16, y: 8 },
      }).setOrigin(0.5)

      card.add([bg, accent, title, subtitle, enterBtn])
      card.setSize(200, 260)
      card.setInteractive({ useHandCursor: true })

      card.on('pointerover', () => bg.setStrokeStyle(2, color, 1))
      card.on('pointerout', () => bg.setStrokeStyle(2, color, 0.6))
      card.on('pointerdown', () => this.scene.start(scene))

      this.tweens.add({
        targets: card,
        y: height * 0.5 - 8,
        duration: 1200 + Math.random() * 400,
        yoyo: true,
        repeat: -1,
        ease: 'Sine.easeInOut',
      })
    })

    // Back button
    this.add
      .text(40, 40, '← MENU', {
        fontFamily: 'monospace',
        fontSize: '14px',
        color: '#6366f1',
      })
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => this.scene.start('MainMenuScene'))
  }
}
