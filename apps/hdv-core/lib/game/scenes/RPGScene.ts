import Phaser from 'phaser'
import type { Entity } from '@/types/entities'
import type { EntityRole, FactionId } from '@/types/character'
import { ALL_ENTITIES, getRandomEncounter } from '@/lib/game/data/entities'
import { FACTIONS } from '@/lib/game/data/factions'

const STARTER_ROLES: EntityRole[] = ['warrior', 'guardian', 'trickster']
const ENEMY_FACTIONS: FactionId[] = ['veiled_current', 'sovereign_crown', 'wildlands_ascendants']

const ROLE_ICON: Record<string, string> = {
  warrior: '⚔',
  guardian: '\u{1F6E1}',
  trickster: '\u{1F3AD}',
}

interface CompanionCard {
  entity: Entity
  bg: Phaser.GameObjects.Rectangle
  container: Phaser.GameObjects.Container
}

export class RPGScene extends Phaser.Scene {
  private cards: CompanionCard[] = []
  private selected: Entity | null = null
  private encounterBtn!: Phaser.GameObjects.Text
  private hopePulse!: Phaser.GameObjects.Text

  constructor() {
    super({ key: 'RPGScene' })
  }

  create() {
    const { width, height } = this.cameras.main
    this.cards = []

    this.add.rectangle(width / 2, height / 2, width, height, 0x0a1a0a)

    this.add
      .text(width / 2, height * 0.08, 'CHRONICLES', {
        fontFamily: 'monospace',
        fontSize: '32px',
        color: '#22c55e',
      })
      .setOrigin(0.5)

    this.add
      .text(width / 2, height * 0.16, 'Choose a companion, then seek an encounter in the field.', {
        fontFamily: 'monospace',
        fontSize: '13px',
        color: '#86efac',
        align: 'center',
      })
      .setOrigin(0.5)

    const starters = STARTER_ROLES.map(
      (role) => ALL_ENTITIES.find((e) => e.tier === 1 && e.role === role)!,
    )

    const cardWidth = Math.min(220, width * 0.26)
    const spacing = width * 0.28
    const startX = width / 2 - spacing

    starters.forEach((entity, i) => {
      this.cards.push(this.buildCompanionCard(entity, startX + i * spacing, height * 0.42, cardWidth))
    })

    const stored = this.registry.get('playerCompanion') as Entity | undefined
    this.selected = stored && starters.find((e) => e.id === stored.id) ? stored : starters[0]
    this.registry.set('playerCompanion', this.selected)

    this.encounterBtn = this.add
      .text(width / 2, height * 0.74, '[ FIND ENCOUNTER ]', {
        fontFamily: 'monospace',
        fontSize: '16px',
        color: '#e2e8f0',
        backgroundColor: '#16a34a',
        padding: { x: 20, y: 10 },
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true })

    this.encounterBtn.on('pointerover', () => this.encounterBtn.setAlpha(0.85))
    this.encounterBtn.on('pointerout', () => this.encounterBtn.setAlpha(1))
    this.encounterBtn.on('pointerdown', () => this.startEncounter())

    this.hopePulse = this.add
      .text(width / 2, height * 0.86, '✦  HOPE is watching over you  ✦', {
        fontFamily: 'monospace',
        fontSize: '12px',
        color: '#7c3aed',
      })
      .setOrigin(0.5)

    this.tweens.add({
      targets: this.hopePulse,
      alpha: 0,
      duration: 1500,
      yoyo: true,
      repeat: -1,
      ease: 'Sine.easeInOut',
    })

    this.add
      .text(40, 40, '← MODES', {
        fontFamily: 'monospace',
        fontSize: '14px',
        color: '#22c55e',
      })
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => this.scene.start('ModeSelectorScene'))

    this.refreshSelection()
  }

  private buildCompanionCard(entity: Entity, x: number, y: number, cardWidth: number): CompanionCard {
    const accent = FACTIONS[entity.faction]?.colorScheme.glowHex ?? 0x6366f1
    const icon = ROLE_ICON[entity.role] ?? '❈'

    const container = this.add.container(x, y)

    const bg = this.add.rectangle(0, 0, cardWidth, 200, 0x1a1a2e)
    bg.setStrokeStyle(2, accent, 0.6)

    const iconText = this.add
      .text(0, -70, icon, { fontFamily: 'monospace', fontSize: '28px' })
      .setOrigin(0.5)

    const nameText = this.add
      .text(0, -32, entity.name, {
        fontFamily: 'monospace',
        fontSize: '15px',
        color: '#e2e8f0',
        align: 'center',
        wordWrap: { width: cardWidth - 16 },
      })
      .setOrigin(0.5)

    const roleText = this.add
      .text(0, -2, `T${entity.tier} ${entity.role.toUpperCase()}`, {
        fontFamily: 'monospace',
        fontSize: '11px',
        color: '#6366f1',
      })
      .setOrigin(0.5)

    const statsText = this.add
      .text(
        0,
        28,
        `PWR ${entity.stats.power}  AGI ${entity.stats.agility}\nRES ${entity.stats.resonance}  FRQ ${entity.stats.frequency}`,
        {
          fontFamily: 'monospace',
          fontSize: '10px',
          color: '#94a3b8',
          align: 'center',
        },
      )
      .setOrigin(0.5)

    const selectLabel = this.add
      .text(0, 80, 'SELECT', {
        fontFamily: 'monospace',
        fontSize: '11px',
        color: '#94a3b8',
        letterSpacing: 2,
      })
      .setOrigin(0.5)

    container.add([bg, iconText, nameText, roleText, statsText, selectLabel])
    container.setSize(cardWidth, 200)
    container.setInteractive({ useHandCursor: true })

    container.on('pointerover', () => {
      if (this.selected?.id !== entity.id) bg.setStrokeStyle(2, accent, 1)
    })
    container.on('pointerout', () => {
      if (this.selected?.id !== entity.id) bg.setStrokeStyle(2, accent, 0.6)
    })
    container.on('pointerdown', () => {
      this.selected = entity
      this.registry.set('playerCompanion', entity)
      this.refreshSelection()
    })

    return { entity, bg, container }
  }

  private refreshSelection() {
    this.cards.forEach(({ entity, bg }) => {
      const accent = FACTIONS[entity.faction]?.colorScheme.glowHex ?? 0x6366f1
      const isSelected = this.selected?.id === entity.id
      bg.setStrokeStyle(isSelected ? 4 : 2, accent, isSelected ? 1 : 0.6)
      bg.setFillStyle(isSelected ? 0x23233f : 0x1a1a2e)
    })
  }

  private startEncounter() {
    if (!this.selected) return

    const faction = ENEMY_FACTIONS[Math.floor(Math.random() * ENEMY_FACTIONS.length)]
    const tier = Math.min(5, this.selected.tier + 1) as 1 | 2 | 3 | 4 | 5
    const enemy = getRandomEncounter(faction, tier)

    this.scene.start('BattleScene', { playerEntity: this.selected, enemyEntity: enemy })
  }
}
