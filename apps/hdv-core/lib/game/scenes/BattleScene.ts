import Phaser from 'phaser'
import type { Entity } from '@/types/entities'
import { resolveRPS, getRandomEncounter } from '@/lib/game/data/entities'
import { FACTIONS } from '@/lib/game/data/factions'

export interface BattleData {
  playerEntity?: Entity
  enemyEntity?: Entity
}

interface Combatant {
  entity: Entity
  maxHp: number
  hp: number
  defending: boolean
}

type Action = 'ATTACK' | 'SPECIAL' | 'DEFEND' | 'FLEE'

const ROLE_ICON: Record<string, string> = {
  warrior: '⚔',
  guardian: '\u{1F6E1}',
  trickster: '\u{1F3AD}',
}

function maxHpFor(entity: Entity): number {
  return Math.round(60 + entity.tier * 15 + entity.stats.resonance * 2)
}

export class BattleScene extends Phaser.Scene {
  private player!: Combatant
  private enemy!: Combatant
  private playerTurn = true
  private actionsEnabled = true
  private over = false

  private logText!: Phaser.GameObjects.Text
  private logLines: string[] = []

  private playerHpGfx!: Phaser.GameObjects.Graphics
  private enemyHpGfx!: Phaser.GameObjects.Graphics
  private playerHpLabel!: Phaser.GameObjects.Text
  private enemyHpLabel!: Phaser.GameObjects.Text
  private turnLabel!: Phaser.GameObjects.Text
  private actionButtons: Phaser.GameObjects.Text[] = []

  // Layout cached for HP bar redraws
  private playerHpBarRect = { x: 0, y: 0, w: 0, h: 0 }
  private enemyHpBarRect = { x: 0, y: 0, w: 0, h: 0 }

  constructor() {
    super({ key: 'BattleScene' })
  }

  init(data: BattleData) {
    const playerEntity = data.playerEntity ?? getRandomEncounter('veiled_current', 1)
    const enemyEntity = data.enemyEntity ?? getRandomEncounter('wildlands_ascendants', 1)

    this.player = {
      entity: playerEntity,
      maxHp: maxHpFor(playerEntity),
      hp: maxHpFor(playerEntity),
      defending: false,
    }
    this.enemy = {
      entity: enemyEntity,
      maxHp: maxHpFor(enemyEntity),
      hp: maxHpFor(enemyEntity),
      defending: false,
    }

    this.playerTurn = playerEntity.stats.agility >= enemyEntity.stats.agility
    this.logLines = []
    this.actionsEnabled = true
    this.over = false
    this.actionButtons = []
  }

  create() {
    const { width, height } = this.cameras.main

    this.add.rectangle(width / 2, height / 2, width, height, 0x0f0f1a)

    this.add
      .text(width / 2, height * 0.05, 'BATTLE', {
        fontFamily: 'monospace',
        fontSize: '20px',
        color: '#a855f7',
        letterSpacing: 4,
      })
      .setOrigin(0.5)

    // Enemy panel (top)
    const enemyRefs = this.buildCombatantPanel(this.enemy, width / 2, height * 0.16, width * 0.7)
    this.enemyHpGfx = enemyRefs.hpGfx
    this.enemyHpLabel = enemyRefs.hpLabel
    this.enemyHpBarRect = enemyRefs.barRect

    // VS divider
    this.add
      .text(width / 2, height * 0.3, 'VS', {
        fontFamily: 'monospace',
        fontSize: '16px',
        color: '#4a4a6a',
        letterSpacing: 4,
      })
      .setOrigin(0.5)

    // Player panel (below VS)
    const playerRefs = this.buildCombatantPanel(this.player, width / 2, height * 0.42, width * 0.7)
    this.playerHpGfx = playerRefs.hpGfx
    this.playerHpLabel = playerRefs.hpLabel
    this.playerHpBarRect = playerRefs.barRect

    // Battle log
    this.add.rectangle(width / 2, height * 0.62, width * 0.86, height * 0.18, 0x1a1a2e).setStrokeStyle(1, 0x6366f1, 0.4)
    this.logText = this.add.text(width * 0.08, height * 0.55, '', {
      fontFamily: 'monospace',
      fontSize: '12px',
      color: '#e2e8f0',
      lineSpacing: 6,
      wordWrap: { width: width * 0.8 },
    })

    this.turnLabel = this.add
      .text(width / 2, height * 0.74, '', {
        fontFamily: 'monospace',
        fontSize: '12px',
        color: '#6366f1',
        letterSpacing: 2,
      })
      .setOrigin(0.5)

    // Action buttons
    const actions: { label: string; action: Action; color: number }[] = [
      { label: 'ATTACK', action: 'ATTACK', color: 0xef4444 },
      { label: 'SPECIAL', action: 'SPECIAL', color: 0xa855f7 },
      { label: 'DEFEND', action: 'DEFEND', color: 0x3b82f6 },
      { label: 'FLEE', action: 'FLEE', color: 0x6b7280 },
    ]

    const btnY = height * 0.88
    const spacing = width * 0.2
    const startX = width / 2 - spacing * 1.5

    actions.forEach(({ label, action, color }, i) => {
      const btn = this.add
        .text(startX + i * spacing, btnY, `[ ${label} ]`, {
          fontFamily: 'monospace',
          fontSize: '13px',
          color: '#e2e8f0',
          backgroundColor: '#' + color.toString(16).padStart(6, '0'),
          padding: { x: 12, y: 8 },
        })
        .setOrigin(0.5)
        .setInteractive({ useHandCursor: true })

      btn.on('pointerover', () => btn.setAlpha(0.85))
      btn.on('pointerout', () => btn.setAlpha(1))
      btn.on('pointerdown', () => this.handlePlayerAction(action))

      this.actionButtons.push(btn)
    })

    this.appendLog(`A wild ${this.enemy.entity.name} (${this.enemy.entity.title}) appears!`)
    this.recordEntity(this.enemy.entity.id, false)
    this.updateHpBars()
    this.updateTurnLabel()

    if (!this.playerTurn) {
      this.setActionsEnabled(false)
      this.time.delayedCall(700, () => this.enemyAction())
    }
  }

  private buildCombatantPanel(c: Combatant, centerX: number, centerY: number, panelWidth: number) {
    const faction = FACTIONS[c.entity.faction]
    const accent = faction?.colorScheme.glowHex ?? 0x6366f1
    const icon = ROLE_ICON[c.entity.role] ?? '❈'

    const bg = this.add.rectangle(centerX, centerY, panelWidth, 64, 0x1a1a2e)
    bg.setStrokeStyle(2, accent, 0.6)

    this.add
      .text(centerX - panelWidth / 2 + 14, centerY - 22, `${icon}  ${c.entity.name}`, {
        fontFamily: 'monospace',
        fontSize: '15px',
        color: '#e2e8f0',
      })
      .setOrigin(0, 0.5)

    this.add
      .text(centerX - panelWidth / 2 + 14, centerY, `${c.entity.title}  ·  T${c.entity.tier} ${c.entity.role.toUpperCase()}`, {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: '#6366f1',
      })
      .setOrigin(0, 0.5)

    const barRect = {
      x: centerX - panelWidth / 2 + 14,
      y: centerY + 16,
      w: panelWidth - 28,
      h: 10,
    }

    this.add.rectangle(barRect.x, barRect.y, barRect.w, barRect.h, 0x0f0f1a).setOrigin(0, 0.5).setStrokeStyle(1, accent, 0.5)

    const hpGfx = this.add.graphics()

    const hpLabel = this.add
      .text(centerX + panelWidth / 2 - 14, centerY + 16, '', {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: '#94a3b8',
      })
      .setOrigin(1, 0.5)

    return { hpGfx, hpLabel, barRect }
  }

  private updateHpBars() {
    this.drawHpBar(this.playerHpGfx, this.playerHpBarRect, this.player)
    this.playerHpLabel.setText(`${Math.max(0, this.player.hp)} / ${this.player.maxHp}`)

    this.drawHpBar(this.enemyHpGfx, this.enemyHpBarRect, this.enemy)
    this.enemyHpLabel.setText(`${Math.max(0, this.enemy.hp)} / ${this.enemy.maxHp}`)
  }

  private drawHpBar(gfx: Phaser.GameObjects.Graphics, rect: { x: number; y: number; w: number; h: number }, c: Combatant) {
    const ratio = Phaser.Math.Clamp(c.hp / c.maxHp, 0, 1)
    const color = ratio > 0.5 ? 0x22c55e : ratio > 0.2 ? 0xf59e0b : 0xef4444

    gfx.clear()
    gfx.fillStyle(color, 1)
    gfx.fillRect(rect.x, rect.y - rect.h / 2, rect.w * ratio, rect.h)
  }

  private updateTurnLabel() {
    if (this.over) return
    this.turnLabel.setText(this.playerTurn ? 'YOUR TURN' : `${this.enemy.entity.name.toUpperCase()}'S TURN`)
  }

  private appendLog(line: string) {
    this.logLines.push(line)
    if (this.logLines.length > 5) this.logLines = this.logLines.slice(-5)
    this.logText.setText(this.logLines.map((l) => `> ${l}`).join('\n'))
  }

  private setActionsEnabled(enabled: boolean) {
    this.actionsEnabled = enabled
    this.actionButtons.forEach((btn) => {
      btn.setAlpha(enabled ? 1 : 0.35)
      if (enabled) btn.setInteractive({ useHandCursor: true })
      else btn.disableInteractive()
    })
  }

  private computeDamage(attacker: Combatant, defender: Combatant, action: 'ATTACK' | 'SPECIAL'): number {
    const baseStat =
      action === 'ATTACK'
        ? attacker.entity.stats.power
        : (attacker.entity.stats.resonance + attacker.entity.stats.frequency) / 2

    let dmg = baseStat * (0.85 + Math.random() * 0.3)

    const rps = resolveRPS(attacker.entity, defender.entity)
    if (rps === 'win') dmg *= 1.5
    else if (rps === 'lose') dmg *= 0.65

    if (defender.defending) {
      dmg *= 0.5
      defender.defending = false
    }

    return Math.max(1, Math.round(dmg))
  }

  private handlePlayerAction(action: Action) {
    if (!this.actionsEnabled || this.over) return

    if (action === 'FLEE') {
      const chance = Phaser.Math.Clamp(
        0.5 + (this.player.entity.stats.agility - this.enemy.entity.stats.agility) * 0.03,
        0.1,
        0.9,
      )
      if (Math.random() < chance) {
        this.appendLog('You slip away into the mist...')
        this.endBattle('fled')
        return
      }
      this.appendLog('Could not escape!')
      this.setActionsEnabled(false)
      this.playerTurn = false
      this.updateTurnLabel()
      this.time.delayedCall(700, () => this.enemyAction())
      return
    }

    if (action === 'DEFEND') {
      this.player.defending = true
      this.appendLog(`${this.player.entity.name} braces for impact.`)
    } else {
      const dmg = this.computeDamage(this.player, this.enemy, action)
      this.enemy.hp = Math.max(0, this.enemy.hp - dmg)

      const rps = resolveRPS(this.player.entity, this.enemy.entity)
      const suffix = rps === 'win' ? ' A devastating blow!' : rps === 'lose' ? ' It barely connects...' : ''

      if (action === 'SPECIAL') {
        this.appendLog(`${this.player.entity.name} uses ${this.player.entity.specialAbility.split(':')[0]}! (${dmg} dmg)${suffix}`)
      } else {
        this.appendLog(`${this.player.entity.name} attacks for ${dmg} damage!${suffix}`)
      }

      this.updateHpBars()

      if (this.enemy.hp <= 0) {
        this.appendLog(`${this.enemy.entity.name} is defeated!`)
        this.recordEntity(this.enemy.entity.id, true)
        this.endBattle('victory')
        return
      }
    }

    this.setActionsEnabled(false)
    this.playerTurn = false
    this.updateTurnLabel()
    this.time.delayedCall(700, () => this.enemyAction())
  }

  private enemyAction() {
    if (this.over) return

    const roll = Math.random()
    const action: 'ATTACK' | 'SPECIAL' | 'DEFEND' = roll < 0.6 ? 'ATTACK' : roll < 0.85 ? 'SPECIAL' : 'DEFEND'

    if (action === 'DEFEND') {
      this.enemy.defending = true
      this.appendLog(`${this.enemy.entity.name} braces for impact.`)
    } else {
      const dmg = this.computeDamage(this.enemy, this.player, action)
      this.player.hp = Math.max(0, this.player.hp - dmg)

      const rps = resolveRPS(this.enemy.entity, this.player.entity)
      const suffix = rps === 'win' ? ' A devastating blow!' : rps === 'lose' ? ' It barely connects...' : ''

      if (action === 'SPECIAL') {
        this.appendLog(`${this.enemy.entity.name} uses ${this.enemy.entity.specialAbility.split(':')[0]}! (${dmg} dmg)${suffix}`)
      } else {
        this.appendLog(`${this.enemy.entity.name} attacks for ${dmg} damage!${suffix}`)
      }

      this.updateHpBars()

      if (this.player.hp <= 0) {
        this.appendLog(`${this.player.entity.name} has fallen!`)
        this.endBattle('defeat')
        return
      }
    }

    this.playerTurn = true
    this.updateTurnLabel()
    this.setActionsEnabled(true)
  }

  private recordEntity(entityId: string, caught: boolean) {
    fetch('/api/entities/record', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ entityId, caught }),
    }).catch(() => {
      // Best-effort OmniDex sync — battle continues regardless.
    })
  }

  private endBattle(result: 'victory' | 'defeat' | 'fled') {
    this.over = true
    this.setActionsEnabled(false)
    this.turnLabel.setText('')

    const { width, height } = this.cameras.main

    const messages: Record<typeof result, { title: string; color: string }> = {
      victory: { title: 'VICTORY', color: '#22c55e' },
      defeat: { title: 'DEFEATED', color: '#ef4444' },
      fled: { title: 'ESCAPED', color: '#6b7280' },
    }
    const { title, color } = messages[result]

    const overlay = this.add.rectangle(width / 2, height / 2, width, height, 0x000000, 0.6)
    const resultText = this.add
      .text(width / 2, height * 0.45, title, {
        fontFamily: 'monospace',
        fontSize: '36px',
        color,
        letterSpacing: 6,
      })
      .setOrigin(0.5)

    const continueBtn = this.add
      .text(width / 2, height * 0.58, '[ RETURN ]', {
        fontFamily: 'monospace',
        fontSize: '16px',
        color: '#e2e8f0',
        backgroundColor: '#7c3aed',
        padding: { x: 20, y: 10 },
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true })

    continueBtn.on('pointerdown', () => this.scene.start('RPGScene'))

    void overlay
    void resultText
  }
}
