import Phaser from 'phaser'
import { FACTIONS } from '@/lib/game/data/factions'

interface GameVariantConfig {
  id: string
  name: string
  primaryColor: number
  accentColor: number
  symbols?: string[]
  ruleKey: string
  minBet: number
  maxBet: number
  houseEdge: number
}

const DEFAULT_SYMBOLS = ['👑', '⚔', '〰', '◉', '✿', '✦', '✧', '❈', '◆']

// Faction groups for bonus payline detection (by symbol index in DEFAULT_SYMBOLS)
const FACTION_GROUPS: number[][] = [
  [0, 1],   // Crown: 👑 ⚔
  [2, 3],   // Veiled: 〰 ◉
  [4, 5],   // Wildlands: ✿ ✦
]

const HOPE_SYMBOL_INDEX = 6   // '✧'
const REEL_COUNT = 3
const ROW_COUNT = 3
const SLOT_SIZE = 90
const REEL_STOP_DELAY = 400   // ms between successive reel stops

function hexToRgbString(hex: number): string {
  return '#' + hex.toString(16).padStart(6, '0')
}

function pickRandom<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)]
}

function inFactionGroup(sym: string, symbols: string[]): number {
  const idx = symbols.indexOf(sym)
  for (let g = 0; g < FACTION_GROUPS.length; g++) {
    if (FACTION_GROUPS[g].includes(idx)) return g
  }
  return -1
}

export class SlotsScene extends Phaser.Scene {
  private variant!: GameVariantConfig
  private symbols!: string[]
  private credits = 1000
  private bet = 10

  // [col][row] of currently shown symbols
  private reelDisplay: string[][] = []

  // Text objects: [col][row]
  private reelTexts: Phaser.GameObjects.Text[][] = []
  // Border rectangles: [col][row]
  private reelBorders: Phaser.GameObjects.Rectangle[][] = []

  private creditText!: Phaser.GameObjects.Text
  private betText!: Phaser.GameObjects.Text
  private statusText!: Phaser.GameObjects.Text
  private paylineGfx!: Phaser.GameObjects.Graphics

  private actionButtons: Phaser.GameObjects.Text[] = []
  private spinning = false
  private reelsSettled = 0

  // Cached payline position
  private paylineY = 0
  private paylineX1 = 0
  private paylineX2 = 0

  constructor() {
    super({ key: 'SlotsScene' })
  }

  init(data: { variant: GameVariantConfig }) {
    this.variant = data.variant
    this.symbols = data.variant.symbols?.length ? data.variant.symbols : DEFAULT_SYMBOLS
    this.credits = 1000
    this.bet = Math.max(data.variant.minBet, 10)
    this.reelDisplay = []
    this.reelTexts = []
    this.reelBorders = []
    this.actionButtons = []
    this.spinning = false
    this.reelsSettled = 0

    for (let col = 0; col < REEL_COUNT; col++) {
      this.reelDisplay[col] = []
      for (let row = 0; row < ROW_COUNT; row++) {
        this.reelDisplay[col][row] = pickRandom(this.symbols)
      }
    }
  }

  create() {
    const { width, height } = this.cameras.main
    const primaryHex = hexToRgbString(this.variant.primaryColor)
    const accentHex = hexToRgbString(this.variant.accentColor)
    const glowHex = hexToRgbString(FACTIONS['sovereign_crown']?.colorScheme.glowHex ?? 0xf59e0b)

    // Background
    this.add.rectangle(width / 2, height / 2, width, height, 0x0f0f1a)

    // ── Title ──────────────────────────────────────────────────────────────
    this.add
      .text(width / 2, height * 0.06, this.variant.name.toUpperCase(), {
        fontFamily: 'monospace',
        fontSize: '20px',
        color: primaryHex,
        letterSpacing: 4,
      })
      .setOrigin(0.5)

    // Decorative separator
    const lineGfx = this.add.graphics()
    lineGfx.lineStyle(1, this.variant.primaryColor, 0.35)
    lineGfx.beginPath()
    lineGfx.moveTo(width * 0.15, height * 0.1)
    lineGfx.lineTo(width * 0.85, height * 0.1)
    lineGfx.strokePath()

    // ── HUD ────────────────────────────────────────────────────────────────
    this.betText = this.add.text(width * 0.07, height * 0.14, '', {
      fontFamily: 'monospace',
      fontSize: '13px',
      color: '#94a3b8',
    })

    this.creditText = this.add
      .text(width * 0.93, height * 0.14, '', {
        fontFamily: 'monospace',
        fontSize: '13px',
        color: '#94a3b8',
      })
      .setOrigin(1, 0)

    this.refreshHUD()

    // ── Reel machine frame ─────────────────────────────────────────────────
    const gapX = 10
    const gapY = 10
    const frameW = REEL_COUNT * SLOT_SIZE + (REEL_COUNT + 1) * gapX
    const frameH = ROW_COUNT * SLOT_SIZE + (ROW_COUNT + 1) * gapY
    const frameX = width / 2
    const frameY = height * 0.45

    this.add
      .rectangle(frameX, frameY, frameW + 20, frameH + 20, 0x1a1a2e)
      .setStrokeStyle(2, this.variant.primaryColor, 0.65)

    // ── Reel slots ─────────────────────────────────────────────────────────
    const startX = frameX - (REEL_COUNT * SLOT_SIZE + (REEL_COUNT - 1) * gapX) / 2 + SLOT_SIZE / 2
    const startY = frameY - (ROW_COUNT * SLOT_SIZE + (ROW_COUNT - 1) * gapY) / 2 + SLOT_SIZE / 2

    for (let col = 0; col < REEL_COUNT; col++) {
      this.reelTexts[col] = []
      this.reelBorders[col] = []
      for (let row = 0; row < ROW_COUNT; row++) {
        const sx = startX + col * (SLOT_SIZE + gapX)
        const sy = startY + row * (SLOT_SIZE + gapY)

        const border = this.add
          .rectangle(sx, sy, SLOT_SIZE, SLOT_SIZE, 0x0f0f1a)
          .setStrokeStyle(1, this.variant.primaryColor, 0.35)
        this.reelBorders[col][row] = border

        const sym = this.add
          .text(sx, sy, this.reelDisplay[col][row], {
            fontFamily: 'monospace',
            fontSize: '38px',
            color: '#e2e8f0',
          })
          .setOrigin(0.5)
        this.reelTexts[col][row] = sym
      }
    }

    // Middle row (row index 1) payline Y
    this.paylineY = startY + SLOT_SIZE + gapY
    this.paylineX1 = startX - SLOT_SIZE / 2 - 6
    this.paylineX2 = startX + (REEL_COUNT - 1) * (SLOT_SIZE + gapX) + SLOT_SIZE / 2 + 6

    // Payline graphics (updated after each spin)
    this.paylineGfx = this.add.graphics()

    // Dim ambient payline stripe
    const stripeGfx = this.add.graphics()
    stripeGfx.lineStyle(2, this.variant.accentColor, 0.12)
    stripeGfx.beginPath()
    stripeGfx.moveTo(this.paylineX1, this.paylineY)
    stripeGfx.lineTo(this.paylineX2, this.paylineY)
    stripeGfx.strokePath()

    // ── Status text ────────────────────────────────────────────────────────
    this.statusText = this.add
      .text(width / 2, height * 0.73, 'PLACE YOUR BET AND SPIN', {
        fontFamily: 'monospace',
        fontSize: '13px',
        color: accentHex,
        letterSpacing: 2,
      })
      .setOrigin(0.5)

    // ── Payline legend ─────────────────────────────────────────────────────
    this.add
      .text(width / 2, height * 0.78, '── payline ──', {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: '#4a4a6a',
      })
      .setOrigin(0.5)

    this.add
      .text(width / 2, height * 0.82, '👑⚔ CROWN  〰◉ VEILED  ✿✦ WILD  ✧ HOPE ×5', {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: '#4a4a6a',
      })
      .setOrigin(0.5)

    // ── Bottom buttons ─────────────────────────────────────────────────────
    const btnY = height * 0.91
    const btnDefs: { label: string; color: number; key: string }[] = [
      { label: 'BET -',   color: 0x475569, key: 'betDown' },
      { label: 'BET +',   color: 0x475569, key: 'betUp'   },
      { label: 'SPIN',    color: this.variant.primaryColor, key: 'spin' },
      { label: 'MAX BET', color: 0x475569, key: 'maxBet'  },
    ]

    const btnSpacing = width * 0.18
    const btnStartX = width / 2 - btnSpacing * 1.5

    btnDefs.forEach(({ label, color, key }, i) => {
      const btn = this.add
        .text(btnStartX + i * btnSpacing, btnY, `[ ${label} ]`, {
          fontFamily: 'monospace',
          fontSize: '13px',
          color: '#e2e8f0',
          backgroundColor: '#' + color.toString(16).padStart(6, '0'),
          padding: { x: 10, y: 8 },
        })
        .setOrigin(0.5)
        .setInteractive({ useHandCursor: true })

      btn.on('pointerover', () => btn.setAlpha(0.8))
      btn.on('pointerout', () => btn.setAlpha(1))
      btn.on('pointerdown', () => this.handleButton(key))

      this.actionButtons.push(btn)
    })

    // ── Back button ────────────────────────────────────────────────────────
    this.add
      .text(40, 40, '← MODES', {
        fontFamily: 'monospace',
        fontSize: '14px',
        color: glowHex,
      })
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => this.scene.start('CasinoScene'))
  }

  // ── Button handling ──────────────────────────────────────────────────────

  private handleButton(key: string) {
    if (this.spinning) return

    switch (key) {
      case 'betDown':
        this.bet = Math.max(this.variant.minBet, this.bet - this.variant.minBet)
        this.refreshHUD()
        break
      case 'betUp':
        this.bet = Math.min(this.variant.maxBet, this.bet + this.variant.minBet)
        this.refreshHUD()
        break
      case 'maxBet':
        this.bet = Math.min(this.variant.maxBet, this.credits)
        this.refreshHUD()
        break
      case 'spin':
        this.startSpin()
        break
    }
  }

  // ── Spin logic ───────────────────────────────────────────────────────────

  private startSpin() {
    if (this.credits < this.bet) {
      this.setStatus('NOT ENOUGH CREDITS', '#ef4444')
      return
    }

    this.credits -= this.bet
    this.refreshHUD()
    this.setButtonsEnabled(false)
    this.paylineGfx.clear()
    this.setStatus('SPINNING...', '#6366f1')
    this.spinning = true
    this.reelsSettled = 0

    for (let col = 0; col < REEL_COUNT; col++) {
      this.animateReel(col)
    }
  }

  private animateReel(col: number) {
    const totalTicks = 8 + Math.floor(Math.random() * 8)   // 8–15 rapid shuffles
    const tickMs = 60
    let tick = 0

    const doTick = () => {
      for (let row = 0; row < ROW_COUNT; row++) {
        const sym = pickRandom(this.symbols)
        this.reelDisplay[col][row] = sym
        this.reelTexts[col][row].setText(sym)
      }

      tick++
      if (tick < totalTicks) {
        this.time.delayedCall(tickMs, doTick)
      } else {
        // Stagger settle: reel 0 stops first, then 400ms per subsequent reel
        this.time.delayedCall(col * REEL_STOP_DELAY, () => this.settleReel(col))
      }
    }

    doTick()
  }

  private settleReel(col: number) {
    for (let row = 0; row < ROW_COUNT; row++) {
      const sym = pickRandom(this.symbols)
      this.reelDisplay[col][row] = sym
      this.reelTexts[col][row].setText(sym)
    }

    // Flash borders to signal lock
    for (let row = 0; row < ROW_COUNT; row++) {
      this.tweens.add({
        targets: this.reelBorders[col][row],
        alpha: 0.4,
        duration: 110,
        yoyo: true,
        repeat: 1,
        onComplete: () => { this.reelBorders[col][row].setAlpha(1) },
      })
    }

    this.reelsSettled++
    if (this.reelsSettled === REEL_COUNT) {
      this.time.delayedCall(250, () => this.evaluateSpin())
    }
  }

  // ── Win evaluation ───────────────────────────────────────────────────────

  private evaluateSpin() {
    this.spinning = false

    // Middle row is the main payline (row index 1)
    const payline = this.reelDisplay.map((col) => col[1])
    const win = this.computeWin(payline)

    if (win > 0) {
      this.credits += win
      this.drawPayline(0x22c55e)
      const label =
        win >= this.bet * 10
          ? `BIG WIN!  +${win} credits`
          : win >= this.bet * 5
            ? `GREAT WIN!  +${win} credits`
            : `WIN  +${win} credits`
      this.setStatus(label, '#22c55e')

      this.tweens.add({
        targets: this.creditText,
        alpha: 0.2,
        duration: 140,
        yoyo: true,
        repeat: 3,
        onComplete: () => { this.creditText.setAlpha(1) },
      })
    } else {
      this.drawPayline(0xef4444)
      this.setStatus('NO WIN — try again', '#6b7280')
    }

    this.refreshHUD()
    this.setButtonsEnabled(true)
  }

  private computeWin(payline: string[]): number {
    const [s0, s1, s2] = payline
    const hopeSymbol = this.symbols[HOPE_SYMBOL_INDEX]
    const hopeMultiplier = payline.includes(hopeSymbol) ? 5 : 1

    let multiplier = 0

    if (s0 === s1 && s1 === s2) {
      // 3-of-a-kind
      multiplier = 10
    } else if (s0 === s1 || s1 === s2 || s0 === s2) {
      // 2-of-a-kind
      multiplier = 2
    } else {
      // Faction group bonus: all 3 from the same faction group
      const g0 = inFactionGroup(s0, this.symbols)
      const g1 = inFactionGroup(s1, this.symbols)
      const g2 = inFactionGroup(s2, this.symbols)
      if (g0 !== -1 && g0 === g1 && g1 === g2) {
        multiplier = 3
      }
    }

    if (multiplier === 0) return 0
    return Math.round(this.bet * multiplier * hopeMultiplier)
  }

  // ── Payline drawing ──────────────────────────────────────────────────────

  private drawPayline(color: number) {
    this.paylineGfx.clear()
    this.paylineGfx.lineStyle(3, color, 0.85)
    this.paylineGfx.beginPath()
    this.paylineGfx.moveTo(this.paylineX1, this.paylineY)
    this.paylineGfx.lineTo(this.paylineX2, this.paylineY)
    this.paylineGfx.strokePath()
  }

  // ── UI helpers ───────────────────────────────────────────────────────────

  private refreshHUD() {
    this.betText.setText(`BET: ${this.bet}`)
    this.creditText.setText(`CREDITS: ${this.credits}`)
  }

  private setStatus(msg: string, color: string) {
    this.statusText.setText(msg)
    this.statusText.setColor(color)
  }

  private setButtonsEnabled(enabled: boolean) {
    this.actionButtons.forEach((btn) => {
      btn.setAlpha(enabled ? 1 : 0.35)
      if (enabled) btn.setInteractive({ useHandCursor: true })
      else btn.disableInteractive()
    })
  }
}
