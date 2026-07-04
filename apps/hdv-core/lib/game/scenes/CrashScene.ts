import Phaser from 'phaser'

export interface GameVariantConfig {
  id: string
  name: string
  primaryColor: number
  accentColor: number
  ruleKey: string
  minBet: number
  maxBet: number
  houseEdge: number
}

type RoundPhase = 'idle' | 'running' | 'crashed'

interface FakePlayer {
  name: string
  bet: number
  cashoutAt: number
  cashedOut: boolean
  label: Phaser.GameObjects.Text
}

interface HistoryEntry {
  value: number
  survived: boolean   // true = player cashed out before crash
}

// Multiplier color based on value
function multiplierColor(mult: number): string {
  if (mult < 2)   return '#e2e8f0'
  if (mult < 5)   return '#22c55e'
  if (mult < 10)  return '#fde68a'
  if (mult < 25)  return '#f97316'
  return '#ef4444'
}

export class CrashScene extends Phaser.Scene {
  private variant!: GameVariantConfig
  private credits = 1000

  private phase: RoundPhase = 'idle'
  private currentMult = 1.0
  private crashPoint  = 2.0
  private playerBet   = 0
  private playerBetPlaced = false
  private playerCashedOut = false

  private multLabel!: Phaser.GameObjects.Text
  private creditsLabel!: Phaser.GameObjects.Text
  private betAmountLabel!: Phaser.GameObjects.Text
  private cashOutBtn!: Phaser.GameObjects.Text
  private startBetBtn!: Phaser.GameObjects.Text
  private betDecrBtn!: Phaser.GameObjects.Text
  private betIncrBtn!: Phaser.GameObjects.Text
  private betPanel!: Phaser.GameObjects.Container
  private betAmount = 10
  private statusLabel!: Phaser.GameObjects.Text
  private glyphLabel!: Phaser.GameObjects.Text

  // Graph
  private graphGfx!: Phaser.GameObjects.Graphics
  private graphX = 0
  private graphY = 0
  private graphW = 0
  private graphH = 0
  private graphPoints: { x: number; y: number }[] = []
  private tickCount = 0

  private tickEvent!: Phaser.Time.TimerEvent

  // History pills
  private history: HistoryEntry[] = []
  private historyLabels: Phaser.GameObjects.Text[] = []

  // Fake players
  private fakePlayers: FakePlayer[] = []

  constructor() {
    super({ key: 'CrashScene' })
  }

  init(data: { variant: GameVariantConfig }) {
    this.variant = data.variant ?? {
      id: 'crash_standard',
      name: 'ASCENSION',
      primaryColor: 0x6366f1,
      accentColor: 0x22c55e,
      ruleKey: 'standard',
      minBet: 5,
      maxBet: 500,
      houseEdge: 0.01,
    }
    this.credits    = 1000
    this.phase      = 'idle'
    this.currentMult = 1.0
    this.playerBet  = 0
    this.playerBetPlaced  = false
    this.playerCashedOut  = false
    this.betAmount  = Math.max(this.variant.minBet, 10)
    this.history    = []
    this.fakePlayers = []
    this.graphPoints = []
    this.tickCount  = 0
  }

  create() {
    const { width, height } = this.cameras.main

    // Deep space background
    this.add.rectangle(width / 2, height / 2, width, height, 0x050510)

    // Subtle star field
    for (let i = 0; i < 60; i++) {
      const star = this.add.graphics()
      star.fillStyle(0xffffff, Phaser.Math.FloatBetween(0.1, 0.5))
      star.fillCircle(
        Phaser.Math.Between(0, width),
        Phaser.Math.Between(0, height),
        Phaser.Math.FloatBetween(0.5, 1.5),
      )
    }

    // Title
    this.add
      .text(width / 2, height * 0.05, this.variant.name, {
        fontFamily: 'monospace',
        fontSize: '22px',
        color: '#' + this.variant.primaryColor.toString(16).padStart(6, '0'),
        letterSpacing: 4,
      })
      .setOrigin(0.5)

    // Back button top-left
    this.add
      .text(40, 36, '[ BACK ]', {
        fontFamily: 'monospace',
        fontSize: '13px',
        color: '#94a3b8',
        backgroundColor: '#1a1a2e',
        padding: { x: 10, y: 6 },
      })
      .setOrigin(0, 0.5)
      .setInteractive({ useHandCursor: true })
      .on('pointerover', function (this: Phaser.GameObjects.Text) { this.setAlpha(0.75) })
      .on('pointerout', function (this: Phaser.GameObjects.Text) { this.setAlpha(1) })
      .on('pointerdown', () => this.scene.start('CasinoScene'))

    // Credits top-right
    this.creditsLabel = this.add
      .text(width - 20, 20, `CREDITS: ${this.credits}`, {
        fontFamily: 'monospace',
        fontSize: '14px',
        color: '#fde68a',
      })
      .setOrigin(1, 0)

    // Graph area
    this.graphX = width * 0.08
    this.graphY = height * 0.15
    this.graphW = width * 0.86
    this.graphH = height * 0.35

    // Graph border/bg
    const graphBg = this.add.graphics()
    graphBg.fillStyle(0x0a0a1a, 0.9)
    graphBg.fillRect(this.graphX, this.graphY, this.graphW, this.graphH)
    graphBg.lineStyle(1, 0x6366f1, 0.3)
    graphBg.strokeRect(this.graphX, this.graphY, this.graphW, this.graphH)

    this.graphGfx = this.add.graphics()

    // Multiplier display (giant text center of graph area)
    this.multLabel = this.add
      .text(width / 2, this.graphY + this.graphH * 0.4, '1.00x', {
        fontFamily: 'monospace',
        fontSize: '52px',
        color: '#e2e8f0',
        letterSpacing: 2,
      })
      .setOrigin(0.5)

    // HOPE glyph that rides the curve
    this.glyphLabel = this.add
      .text(this.graphX, this.graphY + this.graphH, '✦', {
        fontFamily: 'monospace',
        fontSize: '18px',
        color: '#a855f7',
      })
      .setOrigin(0.5)

    // Status line below graph
    this.statusLabel = this.add
      .text(width / 2, this.graphY + this.graphH + 18, '', {
        fontFamily: 'monospace',
        fontSize: '12px',
        color: '#94a3b8',
        align: 'center',
      })
      .setOrigin(0.5, 0)

    // History pills row
    this.buildHistoryRow(width, height)

    // Fake players panel
    this.buildFakePlayers(width, height)

    // Bet panel (between rounds)
    this.buildBetPanel(width, height)

    // Cash-out button (active during round)
    this.cashOutBtn = this.add
      .text(width / 2, height * 0.92, '[ CASH OUT ]', {
        fontFamily: 'monospace',
        fontSize: '18px',
        color: '#0f0f1a',
        backgroundColor: '#22c55e',
        padding: { x: 24, y: 12 },
      })
      .setOrigin(0.5)
      .setAlpha(0.3)
      .disableInteractive()

    this.updateCreditsLabel()
    this.statusLabel.setText('Place a bet and press START BET to enter the round.')
  }

  // ─── UI builders ─────────────────────────────────────────────────────────────

  private buildHistoryRow(width: number, height: number) {
    this.add
      .text(width * 0.08, height * 0.57, 'HISTORY:', {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: '#4a4a6a',
      })
      .setOrigin(0, 0.5)

    for (let i = 0; i < 5; i++) {
      const pill = this.add
        .text(width * 0.19 + i * 60, height * 0.57, '—', {
          fontFamily: 'monospace',
          fontSize: '11px',
          color: '#4a4a6a',
          backgroundColor: '#1a1a2e',
          padding: { x: 6, y: 3 },
        })
        .setOrigin(0, 0.5)
      this.historyLabels.push(pill)
    }
  }

  private buildFakePlayers(width: number, height: number) {
    const fakeNames  = ['SPECTER', 'Nx0va', 'Veilborn', 'ASHKIRA', 'DUSK_7']
    const chosen     = Phaser.Utils.Array.Shuffle([...fakeNames]).slice(0, 3) as string[]

    this.add
      .text(width * 0.08, height * 0.63, 'PLAYERS:', {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: '#4a4a6a',
      })
      .setOrigin(0, 0)

    chosen.forEach((name, i) => {
      const fakeBet    = Phaser.Math.Between(5, 80)
      const cashoutAt  = Phaser.Math.FloatBetween(1.1, 8.0)
      const lbl = this.add
        .text(width * 0.08 + i * (width * 0.28), height * 0.67, `${name}  ${fakeBet}cr`, {
          fontFamily: 'monospace',
          fontSize: '10px',
          color: '#6366f1',
          backgroundColor: '#1a1a2e',
          padding: { x: 5, y: 3 },
        })
        .setOrigin(0, 0)

      this.fakePlayers.push({ name, bet: fakeBet, cashoutAt, cashedOut: false, label: lbl })
    })
  }

  private buildBetPanel(width: number, height: number) {
    const panelY = height * 0.78
    const accent = '#' + this.variant.accentColor.toString(16).padStart(6, '0')

    this.betPanel = this.add.container(0, 0)

    const betMinusBtn = this.add
      .text(width * 0.3, panelY, '[ BET - ]', {
        fontFamily: 'monospace',
        fontSize: '12px',
        color: '#e2e8f0',
        backgroundColor: '#1a1a2e',
        padding: { x: 8, y: 6 },
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => {
        this.betAmount = Math.max(this.variant.minBet, this.betAmount - 5)
        this.betAmountLabel.setText(` ${this.betAmount} `)
      })

    this.betAmountLabel = this.add
      .text(width * 0.5, panelY, ` ${this.betAmount} `, {
        fontFamily: 'monospace',
        fontSize: '18px',
        color: accent,
        backgroundColor: '#1a1a2e',
        padding: { x: 8, y: 5 },
      })
      .setOrigin(0.5)

    const betPlusBtn = this.add
      .text(width * 0.7, panelY, '[ BET + ]', {
        fontFamily: 'monospace',
        fontSize: '12px',
        color: '#e2e8f0',
        backgroundColor: '#1a1a2e',
        padding: { x: 8, y: 6 },
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => {
        this.betAmount = Math.min(this.variant.maxBet, this.credits, this.betAmount + 5)
        this.betAmountLabel.setText(` ${this.betAmount} `)
      })

    this.startBetBtn = this.add
      .text(width / 2, panelY + 38, '[ START BET ]', {
        fontFamily: 'monospace',
        fontSize: '15px',
        color: '#0f0f1a',
        backgroundColor: '#' + this.variant.primaryColor.toString(16).padStart(6, '0'),
        padding: { x: 18, y: 10 },
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true })
      .on('pointerover', () => this.startBetBtn.setAlpha(0.8))
      .on('pointerout', () => this.startBetBtn.setAlpha(1))
      .on('pointerdown', () => this.placeBetAndStart())

    this.betDecrBtn = betMinusBtn
    this.betIncrBtn = betPlusBtn

    this.betPanel.add([betMinusBtn, this.betAmountLabel, betPlusBtn, this.startBetBtn])
  }

  // ─── Game logic ──────────────────────────────────────────────────────────────

  private placeBetAndStart() {
    if (this.phase !== 'idle') return
    if (this.betAmount > this.credits) {
      this.statusLabel.setText('Not enough credits!')
      return
    }
    this.playerBet        = this.betAmount
    this.playerBetPlaced  = true
    this.playerCashedOut  = false
    this.credits         -= this.playerBet
    this.updateCreditsLabel()

    this.startRound()
  }

  private startRound() {
    this.phase       = 'running'
    this.currentMult = 1.0
    this.tickCount   = 0
    this.graphPoints = []

    // Compute crash point
    let cp = 0.99 / (1 - Math.random())
    if (this.variant.ruleKey === 'safe') cp = Math.min(cp, 20)
    this.crashPoint = Math.min(cp, 100)

    // Reset fake players
    this.fakePlayers.forEach((fp) => {
      fp.cashedOut = false
      fp.cashoutAt = Phaser.Math.FloatBetween(1.1, Math.min(this.crashPoint * 0.9, 8.0))
    })

    // Update UI
    this.multLabel.setText('1.00x').setColor('#e2e8f0')
    this.statusLabel.setText('ROUND IN PROGRESS...')
    this.betPanel.setAlpha(0.25)
    this.betDecrBtn.disableInteractive()
    this.betIncrBtn.disableInteractive()
    this.startBetBtn.disableInteractive()

    if (this.playerBetPlaced) {
      this.cashOutBtn.setAlpha(1).setInteractive({ useHandCursor: true })
        .on('pointerover', () => this.cashOutBtn.setAlpha(0.85))
        .on('pointerout', () => this.cashOutBtn.setAlpha(1))
        .on('pointerdown', () => this.doCashOut())
    }

    // Tick interval
    const intervalMs = this.variant.ruleKey === 'turbo' ? 30 : 50
    const increment  = this.variant.ruleKey === 'turbo' ? 0.02 : 0.01

    this.tickEvent = this.time.addEvent({
      delay: intervalMs,
      loop: true,
      callback: () => this.onTick(increment),
    })
  }

  private onTick(increment: number) {
    this.currentMult = parseFloat((this.currentMult + increment).toFixed(2))
    this.tickCount++

    this.multLabel.setText(`${this.currentMult.toFixed(2)}x`)
    this.multLabel.setColor(multiplierColor(this.currentMult))

    // Update graph
    this.updateGraph()

    // Fake players cash out
    this.fakePlayers.forEach((fp) => {
      if (!fp.cashedOut && this.currentMult >= fp.cashoutAt) {
        fp.cashedOut = true
        const gain = Math.round(fp.bet * fp.cashoutAt)
        fp.label.setText(`${fp.name}  +${gain}cr  ✓`).setColor('#22c55e')
      }
    })

    // Check crash
    if (this.currentMult >= this.crashPoint) {
      this.onCrash()
    }
  }

  private doCashOut() {
    if (this.phase !== 'running' || this.playerCashedOut || !this.playerBetPlaced) return
    this.playerCashedOut = true
    const gain = Math.round(this.playerBet * this.currentMult)
    this.credits += gain
    this.updateCreditsLabel()
    this.statusLabel.setText(`Cashed out at ${this.currentMult.toFixed(2)}x  →  +${gain} credits!`)
    this.cashOutBtn.setAlpha(0.3).disableInteractive()
  }

  private onCrash() {
    this.tickEvent.remove(false)
    this.phase = 'crashed'

    const crashLabel = this.crashPoint.toFixed(2)

    if (this.playerBetPlaced && !this.playerCashedOut) {
      this.statusLabel.setText(`CRASHED at ${crashLabel}x  —  lost ${this.playerBet} credits.`)
    } else if (!this.playerBetPlaced) {
      this.statusLabel.setText(`CRASHED at ${crashLabel}x`)
    }

    // Big crash overlay text
    const { width, height } = this.cameras.main
    const crashText = this.add
      .text(width / 2, this.graphY + this.graphH * 0.4, `CRASHED\n${crashLabel}x`, {
        fontFamily: 'monospace',
        fontSize: '36px',
        color: '#ef4444',
        align: 'center',
        letterSpacing: 4,
      })
      .setOrigin(0.5)

    // Track history
    const survived = this.playerBetPlaced && this.playerCashedOut
    this.history.unshift({ value: this.crashPoint, survived })
    if (this.history.length > 5) this.history.length = 5
    this.updateHistoryPills()

    this.cashOutBtn.setAlpha(0.3).disableInteractive()
    this.multLabel.setColor('#ef4444')

    // Restart after 2s
    this.time.delayedCall(2000, () => {
      crashText.destroy()
      this.resetForNextRound()
    })
  }

  private resetForNextRound() {
    this.phase           = 'idle'
    this.playerBetPlaced = false
    this.playerCashedOut = false
    this.currentMult     = 1.0
    this.graphPoints     = []
    this.graphGfx.clear()

    this.multLabel.setText('1.00x').setColor('#e2e8f0')
    this.statusLabel.setText('Place a bet and press START BET to enter the round.')

    this.betPanel.setAlpha(1)
    this.betDecrBtn.setInteractive({ useHandCursor: true })
    this.betIncrBtn.setInteractive({ useHandCursor: true })
    this.startBetBtn.setInteractive({ useHandCursor: true })

    // Reset fake player labels
    this.fakePlayers.forEach((fp) => {
      fp.label.setText(`${fp.name}  ${fp.bet}cr`).setColor('#6366f1')
    })

    this.glyphLabel.setPosition(this.graphX, this.graphY + this.graphH)
  }

  // ─── Graph ───────────────────────────────────────────────────────────────────

  private updateGraph() {
    const gfx  = this.graphGfx
    const maxT = Math.max(this.tickCount, 1)

    // Map multiplier to graph coords
    // x: linear time
    // y: log scale for readability
    const multToY = (m: number) => {
      const logM = Math.log(Math.max(m, 1))
      const logC = Math.log(Math.max(this.crashPoint, 1.5))
      return this.graphY + this.graphH - (logM / logC) * this.graphH * 0.9
    }

    const xPos = (tick: number) => this.graphX + (tick / Math.max(maxT + 10, 50)) * this.graphW

    this.graphPoints.push({ x: xPos(this.tickCount), y: multToY(this.currentMult) })

    gfx.clear()
    if (this.graphPoints.length < 2) return

    // Fill under curve
    gfx.fillStyle(this.variant.primaryColor, 0.12)
    gfx.beginPath()
    gfx.moveTo(this.graphX, this.graphY + this.graphH)
    this.graphPoints.forEach((pt) => gfx.lineTo(pt.x, pt.y))
    gfx.lineTo(this.graphPoints[this.graphPoints.length - 1].x, this.graphY + this.graphH)
    gfx.closePath()
    gfx.fillPath()

    // Curve line
    gfx.lineStyle(2, this.variant.primaryColor, 0.9)
    gfx.beginPath()
    gfx.moveTo(this.graphPoints[0].x, this.graphPoints[0].y)
    for (let i = 1; i < this.graphPoints.length; i++) {
      gfx.lineTo(this.graphPoints[i].x, this.graphPoints[i].y)
    }
    gfx.strokePath()

    // Move glyph to curve tip
    const last = this.graphPoints[this.graphPoints.length - 1]
    this.glyphLabel.setPosition(last.x, last.y - 12)
  }

  private updateHistoryPills() {
    this.historyLabels.forEach((pill, i) => {
      const entry = this.history[i]
      if (!entry) {
        pill.setText('—').setColor('#4a4a6a')
        return
      }
      const color = entry.survived ? '#22c55e' : '#ef4444'
      pill.setText(`${entry.value.toFixed(2)}x`).setColor(color)
    })
  }

  private updateCreditsLabel() {
    this.creditsLabel.setText(`CREDITS: ${this.credits}`)
  }
}
