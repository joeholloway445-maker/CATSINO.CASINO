import Phaser from 'phaser'
import { generateMap, TILE_SIZE, MAP_SIZE, ZONE_COLORS, type TileData } from '@/lib/game/maps/ProceduralMap'
import { rollEncounter } from '@/lib/game/entities/EntityManager'
import type { FactionId, SpaceZone } from '@/types/character'

interface PlayerData {
  faction: FactionId
  race: string
  frame: string
  prestige: number
  currencies: {
    coin: number
    chip: number
    fragments: number
    tokens: number
    charges: number
    renown: number
  }
}

const FACTION_COLORS: Record<FactionId, number> = {
  veiled_current: 0x6366f1,
  sovereign_crown: 0xf59e0b,
  wildlands_ascendants: 0x10b981,
}

const PLAYER_SPEED = 100

export class ExtraliminalScene extends Phaser.Scene {
  private map: TileData[][] = []
  private terrainLayer!: Phaser.GameObjects.Graphics
  private entityLayer!: Phaser.GameObjects.Graphics
  private fogLayer!: Phaser.GameObjects.Graphics
  private player!: Phaser.GameObjects.Container
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys
  private wasd: Record<string, Phaser.Input.Keyboard.Key> = {}
  private playerData!: PlayerData
  private currentZone: SpaceZone = 'supraliminal'
  private encounterCooldown = 0
  private hudCamera!: Phaser.Cameras.Scene2D.Camera
  private hudText!: Phaser.GameObjects.Text
  private zoneText!: Phaser.GameObjects.Text
  private encounterText!: Phaser.GameObjects.Text
  private encounterTimer = 0

  constructor() {
    super({ key: 'ExtraliminalScene' })
  }

  init(data: Partial<PlayerData>) {
    this.playerData = {
      faction: data.faction ?? 'veiled_current',
      race: data.race ?? 'ashen_choir',
      frame: data.frame ?? 'strider',
      prestige: data.prestige ?? 1,
      currencies: data.currencies ?? {
        coin: 0, chip: 0, fragments: 0, tokens: 0, charges: 0, renown: 0,
      },
    }
  }

  create() {
    const worldWidth = MAP_SIZE * TILE_SIZE
    const worldHeight = MAP_SIZE * TILE_SIZE

    // Generate world
    this.map = generateMap()

    // Draw terrain
    this.terrainLayer = this.add.graphics()
    this.drawTerrain()

    // Entity markers
    this.entityLayer = this.add.graphics()
    this.drawEntities()

    // Fog of war
    this.fogLayer = this.add.graphics()
    this.drawFog()

    // Player
    this.createPlayer()

    // Camera setup
    this.cameras.main.setBounds(0, 0, worldWidth, worldHeight)
    this.cameras.main.startFollow(this.player, true, 0.08, 0.08)
    this.cameras.main.setZoom(2)

    // Input
    this.cursors = this.input.keyboard!.createCursorKeys()
    this.wasd = this.input.keyboard!.addKeys('W,A,S,D') as Record<string, Phaser.Input.Keyboard.Key>

    // HUD overlay (separate camera, ignores world scroll)
    this.createHUD()

    // Atmosphere particles
    this.createAtmosphere()

    // Back button
    const backBtn = this.add
      .text(12, 12, '← HUB', {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: '#6366f1',
        backgroundColor: '#0f0f1a',
        padding: { x: 6, y: 4 },
      })
      .setDepth(200)
      .setScrollFactor(0)
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => {
        // Signal back to React layer via registry
        this.registry.set('navigateTo', '/game')
      })
  }

  private drawTerrain() {
    const g = this.terrainLayer
    g.clear()
    for (let y = 0; y < MAP_SIZE; y++) {
      for (let x = 0; x < MAP_SIZE; x++) {
        const tile = this.map[y][x]
        const colors = ZONE_COLORS[tile.zone]
        const px = x * TILE_SIZE
        const py = y * TILE_SIZE
        g.fillStyle(colors.fill)
        g.fillRect(px, py, TILE_SIZE, TILE_SIZE)
        g.lineStyle(1, colors.border, 0.25)
        g.strokeRect(px, py, TILE_SIZE, TILE_SIZE)
      }
    }
  }

  private drawEntities() {
    const g = this.entityLayer
    g.clear()
    const factionDotColors: Record<string, number> = {
      veiled_current: 0x818cf8,
      sovereign_crown: 0xfcd34d,
      wildlands_ascendants: 0x6ee7b7,
    }
    for (let y = 0; y < MAP_SIZE; y++) {
      for (let x = 0; x < MAP_SIZE; x++) {
        const tile = this.map[y][x]
        if (tile.hasEntity && tile.entityFaction && tile.explored) {
          const px = x * TILE_SIZE + TILE_SIZE / 2
          const py = y * TILE_SIZE + TILE_SIZE / 2
          const color = factionDotColors[tile.entityFaction] ?? 0xffffff
          g.fillStyle(color, 0.9)
          g.fillCircle(px, py, 5)
          g.lineStyle(1, 0xffffff, 0.3)
          g.strokeCircle(px, py, 5)
        }
      }
    }
  }

  private drawFog() {
    const g = this.fogLayer
    g.clear()
    g.setDepth(50)
    for (let y = 0; y < MAP_SIZE; y++) {
      for (let x = 0; x < MAP_SIZE; x++) {
        if (!this.map[y][x].explored) {
          g.fillStyle(0x000000, 0.85)
          g.fillRect(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
        }
      }
    }
  }

  private createPlayer() {
    const startX = (MAP_SIZE / 2) * TILE_SIZE + TILE_SIZE / 2
    const startY = (MAP_SIZE / 2) * TILE_SIZE + TILE_SIZE / 2
    const color = FACTION_COLORS[this.playerData.faction]

    const shadow = this.add.graphics()
    shadow.fillStyle(0x000000, 0.35)
    shadow.fillEllipse(0, 10, 18, 8)

    const body = this.add.graphics()
    body.fillStyle(color, 1)
    body.fillCircle(0, 0, 10)
    body.fillStyle(0xffffff, 0.4)
    body.fillCircle(-3, -3, 3)
    body.lineStyle(1.5, 0xffffff, 0.6)
    body.strokeCircle(0, 0, 10)

    this.player = this.add.container(startX, startY, [shadow, body])
    this.player.setDepth(100)
  }

  private createHUD() {
    const { width, height } = this.cameras.main

    // Zone indicator
    this.zoneText = this.add
      .text(width / 2, 12, 'SUPRALIMINAL SPACE', {
        fontFamily: 'monospace',
        fontSize: '9px',
        color: '#6366f1',
        backgroundColor: '#0f0f1a',
        padding: { x: 8, y: 4 },
      })
      .setOrigin(0.5, 0)
      .setScrollFactor(0)
      .setDepth(200)

    // Currency HUD — bottom bar
    this.hudText = this.add
      .text(width / 2, height - 10, '', {
        fontFamily: 'monospace',
        fontSize: '8px',
        color: '#a0aec0',
        backgroundColor: '#0f0f1a',
        padding: { x: 8, y: 4 },
      })
      .setOrigin(0.5, 1)
      .setScrollFactor(0)
      .setDepth(200)
    this.updateHUD()

    // Encounter text (center, hidden initially)
    this.encounterText = this.add
      .text(width / 2, height * 0.35, '', {
        fontFamily: 'monospace',
        fontSize: '11px',
        color: '#e879f9',
        backgroundColor: '#0f0f1a',
        padding: { x: 12, y: 6 },
        align: 'center',
      })
      .setOrigin(0.5)
      .setScrollFactor(0)
      .setDepth(200)
      .setVisible(false)
  }

  private updateHUD() {
    const c = this.playerData.currencies
    this.hudText.setText(
      `◈${c.coin}  ⬡${c.chip}  ◆${c.fragments}  ◉${c.tokens}  ⚡${c.charges}  ✦${c.renown}`,
    )
  }

  private createAtmosphere() {
    for (let i = 0; i < 80; i++) {
      const dot = this.add.graphics()
      dot.fillStyle(0xffffff, 0.15)
      dot.fillCircle(0, 0, Phaser.Math.Between(1, 2))
      dot.x = Phaser.Math.Between(0, MAP_SIZE * TILE_SIZE)
      dot.y = Phaser.Math.Between(0, MAP_SIZE * TILE_SIZE)
      dot.setDepth(5)
      this.tweens.add({
        targets: dot,
        alpha: { from: 0.05, to: 0.25 },
        duration: Phaser.Math.Between(1500, 4000),
        yoyo: true,
        repeat: -1,
        ease: 'Sine.easeInOut',
      })
    }
  }

  update(time: number, delta: number) {
    if (!this.player) return
    const dt = delta / 1000

    this.encounterCooldown = Math.max(0, this.encounterCooldown - delta)
    this.encounterTimer = Math.max(0, this.encounterTimer - delta)

    if (this.encounterTimer <= 0 && this.encounterText.visible) {
      this.encounterText.setVisible(false)
    }

    // Movement
    let vx = 0
    let vy = 0
    if (this.cursors.left.isDown || this.wasd['A']?.isDown) vx = -PLAYER_SPEED
    if (this.cursors.right.isDown || this.wasd['D']?.isDown) vx = PLAYER_SPEED
    if (this.cursors.up.isDown || this.wasd['W']?.isDown) vy = -PLAYER_SPEED
    if (this.cursors.down.isDown || this.wasd['S']?.isDown) vy = PLAYER_SPEED

    if (vx !== 0 && vy !== 0) {
      vx *= 0.707
      vy *= 0.707
    }

    const newX = Phaser.Math.Clamp(this.player.x + vx * dt, 16, MAP_SIZE * TILE_SIZE - 16)
    const newY = Phaser.Math.Clamp(this.player.y + vy * dt, 16, MAP_SIZE * TILE_SIZE - 16)
    this.player.x = newX
    this.player.y = newY

    // Tile under player
    const tileX = Math.floor(newX / TILE_SIZE)
    const tileY = Math.floor(newY / TILE_SIZE)
    const tile = this.map[tileY]?.[tileX]
    if (!tile) return

    // Reveal fog in radius
    let fogUpdated = false
    for (let dy = -5; dy <= 5; dy++) {
      for (let dx = -5; dx <= 5; dx++) {
        const nx = tileX + dx
        const ny = tileY + dy
        if (nx < 0 || ny < 0 || nx >= MAP_SIZE || ny >= MAP_SIZE) continue
        const dist = Math.sqrt(dx * dx + dy * dy)
        if (dist <= 4 && !this.map[ny][nx].explored) {
          this.map[ny][nx].explored = true
          fogUpdated = true
        }
      }
    }
    if (fogUpdated) {
      this.drawFog()
      this.drawEntities()
    }

    // Zone change
    if (tile.zone !== this.currentZone) {
      this.currentZone = tile.zone
      const zoneLabels: Record<SpaceZone, string> = {
        supraliminal: 'SUPRALIMINAL SPACE',
        liminal: 'LIMINAL SPACE',
        periliminal: 'PERILIMINAL SPACE',
        subliminal: 'SUBLIMINAL SPACE',
        hyperliminal: 'HYPERLIMINAL SPACE — LOCKED',
      }
      const zoneColors: Record<SpaceZone, string> = {
        supraliminal: '#6366f1',
        liminal: '#a855f7',
        periliminal: '#ef4444',
        subliminal: '#22c55e',
        hyperliminal: '#f59e0b',
      }
      this.zoneText.setText(zoneLabels[tile.zone])
      this.zoneText.setColor(zoneColors[tile.zone])
    }

    // Entity encounter
    if (tile.hasEntity && this.encounterCooldown <= 0) {
      this.encounterCooldown = 8000
      tile.hasEntity = false
      tile.entityFaction = undefined
      this.drawEntities()

      const entity = rollEncounter(tile.zone, this.playerData.faction)
      if (entity) {
        this.playerData.currencies.fragments += entity.tier * 3
        this.playerData.currencies.renown += entity.tier
        this.updateHUD()
        this.persistCurrencyGrant('fragments', entity.tier * 3)
        this.persistCurrencyGrant('renown', entity.tier)

        this.encounterText
          .setText(`✦ ${entity.name.toUpperCase()} ✦\n${entity.title}\n+${entity.tier * 3} Fragments  +${entity.tier} Renown`)
          .setVisible(true)
        this.encounterTimer = 3500

        this.tweens.add({
          targets: this.encounterText,
          scaleX: { from: 0.8, to: 1 },
          scaleY: { from: 0.8, to: 1 },
          alpha: { from: 0, to: 1 },
          duration: 300,
          ease: 'Back.easeOut',
        })
      }
    }
  }

  // Currency gains are applied to this.playerData.currencies immediately for
  // a responsive HUD, but that's purely client-side scene state -- this
  // persists the same gain server-side so it survives reload. Best-effort:
  // a failed network call shouldn't interrupt gameplay.
  private persistCurrencyGrant(currency: 'fragments' | 'renown', amount: number): void {
    fetch('/api/currencies/grant', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ currency, amount }),
    }).catch(() => {})
  }
}
