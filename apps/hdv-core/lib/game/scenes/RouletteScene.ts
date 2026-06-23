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

// Faction colors from factions.ts
const SOVEREIGN_COLOR = 0xf59e0b   // sovereign_crown secondary
const VEILED_COLOR    = 0x6366f1   // veiled_current secondary
const WILDLANDS_COLOR = 0x10b981   // wildlands_ascendants secondary
const HOUSE_COLOR     = 0x16a34a   // green zero

type FactionBet = 'SOVEREIGN' | 'VEILED' | 'WILDLANDS' | null
type ParityBet  = 'ODD' | 'EVEN' | null
type TierBet    = 'LOW' | 'MID' | 'HIGH' | null

interface BetState {
  faction: FactionBet
  parity: ParityBet
  tier: TierBet
  numberBet: number
  useNumberBet: boolean
  amount: number
}

function numberToFaction(n: number): 'SOVEREIGN' | 'VEILED' | 'WILDLANDS' | 'HOUSE' {
  if (n === 0 || n === 37 || n === 38) return 'HOUSE'
  if (n <= 12) return 'SOVEREIGN'
  if (n <= 24) return 'VEILED'
  return 'WILDLANDS'
}

function numberLabel(n: number): string {
  if (n === 37) return '00'
  if (n === 38) return '✦HOPE'
  return String(n)
}

export class RouletteScene extends Phaser.Scene {
  private variant!: GameVariantConfig
  private credits = 1000
  private spinning = false

  private wheelGfx!: Phaser.GameObjects.Graphics
  private wheelAngle = 0
  private totalSlots = 37

  private creditsLabel!: Phaser.GameObjects.Text
  private resultLabel!: Phaser.GameObjects.Text
  private spinBtn!: Phaser.GameObjects.Text
  private betAmountLabel!: Phaser.GameObjects.Text
  private numberBetLabel!: Phaser.GameObjects.Text
  private numberBetToggle!: Phaser.GameObjects.Text

  private bet: BetState = {
    faction: null,
    parity: null,
    tier: null,
    numberBet: 0,
    useNumberBet: false,
    amount: 10,
  }

  private factionBtns: { label: FactionBet; text: Phaser.GameObjects.Text }[] = []
  private parityBtns: { label: ParityBet; text: Phaser.GameObjects.Text }[] = []
  private tierBtns: { label: TierBet; text: Phaser.GameObjects.Text }[] = []

  private wheelCx = 0
  private wheelCy = 0
  private wheelR = 150

  constructor() {
    super({ key: 'RouletteScene' })
  }

  init(data: { variant: GameVariantConfig }) {
    this.variant = data.variant ?? {
      id: 'roulette_european',
      name: 'FATE WHEEL',
      primaryColor: 0x6366f1,
      accentColor: 0xf59e0b,
      ruleKey: 'european',
      minBet: 5,
      maxBet: 500,
      houseEdge: 0.027,
    }
    this.credits = 1000
    this.spinning = false
    this.wheelAngle = 0
    this.bet = {
      faction: null,
      parity: null,
      tier: null,
      numberBet: 0,
      useNumberBet: false,
      amount: Math.max(this.variant.minBet, 10),
    }
    this.factionBtns = []
    this.parityBtns = []
    this.tierBtns = []

    if (this.variant.ruleKey === 'american') {
      this.totalSlots = 38
    } else if (this.variant.ruleKey === 'hdv') {
      this.totalSlots = 39
    } else {
      this.totalSlots = 37
    }
  }

  create() {
    const { width, height } = this.cameras.main

    this.add.rectangle(width / 2, height / 2, width, height, 0x0f0f1a)

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

    // Wheel: left-center
    this.wheelCx = width * 0.28
    this.wheelCy = height * 0.46
    this.wheelR  = Math.min(150, Math.floor(width * 0.18))

    this.wheelGfx = this.add.graphics()
    this.wheelGfx.x = this.wheelCx
    this.wheelGfx.y = this.wheelCy
    this.drawWheel()

    // Static pointer triangle above wheel
    const ptr = this.add.graphics()
    ptr.fillStyle(0xffffff, 1)
    ptr.fillTriangle(
      this.wheelCx,      this.wheelCy - this.wheelR - 14,
      this.wheelCx - 10, this.wheelCy - this.wheelR - 2,
      this.wheelCx + 10, this.wheelCy - this.wheelR - 2,
    )

    // Rule variant tag
    this.add
      .text(this.wheelCx, this.wheelCy + this.wheelR + 10, `RULE: ${this.variant.ruleKey.toUpperCase()}`, {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: '#4a4a6a',
        letterSpacing: 2,
      })
      .setOrigin(0.5, 0)

    // Result label
    this.resultLabel = this.add
      .text(this.wheelCx, this.wheelCy + this.wheelR + 28, '', {
        fontFamily: 'monospace',
        fontSize: '13px',
        color: '#e2e8f0',
        align: 'center',
        wordWrap: { width: this.wheelR * 2 + 20 },
      })
      .setOrigin(0.5, 0)

    // Betting panel right side
    this.buildBettingPanel(width, height)

    this.updateCreditsLabel()
    this.refreshBetHighlights()
  }

  // ─── Wheel drawing ───────────────────────────────────────────────────────────

  private drawWheel() {
    const gfx   = this.wheelGfx
    const r     = this.wheelR
    const slots = this.totalSlots
    const slice = (Math.PI * 2) / slots

    gfx.clear()

    for (let i = 0; i < slots; i++) {
      const startA = i * slice - Math.PI / 2
      const endA   = startA + slice

      let fillColor: number
      if (i === 0) {
        fillColor = HOUSE_COLOR
      } else if (i === 37 && (slots === 38 || slots === 39)) {
        fillColor = HOUSE_COLOR   // 00
      } else if (i === 38 && slots === 39) {
        fillColor = 0xa855f7      // HOPE purple
      } else if (i <= 12) {
        fillColor = SOVEREIGN_COLOR
      } else if (i <= 24) {
        fillColor = VEILED_COLOR
      } else {
        fillColor = WILDLANDS_COLOR
      }

      gfx.fillStyle(fillColor, 1)
      gfx.beginPath()
      gfx.moveTo(0, 0)
      const steps = Math.max(6, Math.ceil(slice * r / 4))
      for (let s = 0; s <= steps; s++) {
        const a = startA + (slice * s) / steps
        gfx.lineTo(Math.cos(a) * r, Math.sin(a) * r)
      }
      gfx.closePath()
      gfx.fillPath()

      // Segment divider line
      gfx.lineStyle(1, 0x0f0f1a, 0.7)
      gfx.beginPath()
      gfx.moveTo(0, 0)
      gfx.lineTo(Math.cos(endA) * r, Math.sin(endA) * r)
      gfx.strokePath()
    }

    // Outer ring
    gfx.lineStyle(3, 0xe2e8f0, 0.5)
    gfx.strokeCircle(0, 0, r)

    // Inner ring
    gfx.lineStyle(1, 0xe2e8f0, 0.2)
    gfx.strokeCircle(0, 0, r * 0.75)

    // Center hub
    gfx.fillStyle(0x0f0f1a, 1)
    gfx.fillCircle(0, 0, r * 0.13)
    gfx.lineStyle(2, 0xe2e8f0, 0.4)
    gfx.strokeCircle(0, 0, r * 0.13)
  }

  // ─── Betting panel ───────────────────────────────────────────────────────────

  private buildBettingPanel(width: number, height: number) {
    const panelX  = width * 0.56
    const panelW  = width * 0.42
    const accent  = '#' + this.variant.accentColor.toString(16).padStart(6, '0')
    const primary = '#' + this.variant.primaryColor.toString(16).padStart(6, '0')
    let curY      = height * 0.11

    const sectionLabel = (text: string, y: number) => {
      this.add.text(panelX, y, text, {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: '#6366f1',
        letterSpacing: 2,
      })
    }

    // ── FACTION BET ──
    sectionLabel('FACTION BET  (2:1)', curY)
    curY += 20

    const factionDefs: { label: FactionBet; display: string }[] = [
      { label: 'SOVEREIGN', display: 'SOVEREIGN' },
      { label: 'VEILED',    display: 'VEILED' },
      { label: 'WILDLANDS', display: 'WILDLANDS' },
    ]
    factionDefs.forEach(({ label, display }, i) => {
      const bx = panelX + i * (panelW / 3)
      const btn = this.add
        .text(bx, curY, `[ ${display} ]`, {
          fontFamily: 'monospace',
          fontSize: '10px',
          color: '#e2e8f0',
          backgroundColor: '#1a1a2e',
          padding: { x: 5, y: 4 },
        })
        .setInteractive({ useHandCursor: true })
        .on('pointerover', () => btn.setAlpha(0.8))
        .on('pointerout', () => btn.setAlpha(1))
        .on('pointerdown', () => {
          this.bet.faction = this.bet.faction === label ? null : label
          this.refreshBetHighlights()
        })
      this.factionBtns.push({ label, text: btn })
    })
    curY += 32

    // ── PARITY BET ──
    sectionLabel('PARITY BET  (1:1)', curY)
    curY += 20

    const parityDefs: { label: ParityBet; display: string }[] = [
      { label: 'ODD',  display: 'ODD' },
      { label: 'EVEN', display: 'EVEN' },
    ]
    parityDefs.forEach(({ label, display }, i) => {
      const bx = panelX + i * (panelW / 2.5)
      const btn = this.add
        .text(bx, curY, `[ ${display} ]`, {
          fontFamily: 'monospace',
          fontSize: '10px',
          color: '#e2e8f0',
          backgroundColor: '#1a1a2e',
          padding: { x: 5, y: 4 },
        })
        .setInteractive({ useHandCursor: true })
        .on('pointerover', () => btn.setAlpha(0.8))
        .on('pointerout', () => btn.setAlpha(1))
        .on('pointerdown', () => {
          this.bet.parity = this.bet.parity === label ? null : label
          this.refreshBetHighlights()
        })
      this.parityBtns.push({ label, text: btn })
    })
    curY += 32

    // ── TIER BET ──
    sectionLabel('TIER BET  (2:1)', curY)
    curY += 20

    const tierDefs: { label: TierBet; display: string }[] = [
      { label: 'LOW',  display: 'LOW 1-12' },
      { label: 'MID',  display: 'MID 13-24' },
      { label: 'HIGH', display: 'HIGH 25-36' },
    ]
    tierDefs.forEach(({ label, display }, i) => {
      const bx = panelX + i * (panelW / 3)
      const btn = this.add
        .text(bx, curY, `[ ${display} ]`, {
          fontFamily: 'monospace',
          fontSize: '10px',
          color: '#e2e8f0',
          backgroundColor: '#1a1a2e',
          padding: { x: 5, y: 4 },
        })
        .setInteractive({ useHandCursor: true })
        .on('pointerover', () => btn.setAlpha(0.8))
        .on('pointerout', () => btn.setAlpha(1))
        .on('pointerdown', () => {
          this.bet.tier = this.bet.tier === label ? null : label
          this.refreshBetHighlights()
        })
      this.tierBtns.push({ label, text: btn })
    })
    curY += 32

    // ── NUMBER BET ──
    const maxNumber = this.totalSlots - 1
    sectionLabel(`NUMBER BET  (35:1)`, curY)
    curY += 20

    this.numberBetToggle = this.add
      .text(panelX, curY, '[ ACTIVATE ]', {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: '#e2e8f0',
        backgroundColor: '#1a1a2e',
        padding: { x: 6, y: 4 },
      })
      .setInteractive({ useHandCursor: true })
      .on('pointerover', () => this.numberBetToggle.setAlpha(0.8))
      .on('pointerout', () => this.numberBetToggle.setAlpha(1))
      .on('pointerdown', () => {
        this.bet.useNumberBet = !this.bet.useNumberBet
        this.refreshBetHighlights()
      })

    this.add
      .text(panelX + 100, curY, '[ - ]', {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: '#e2e8f0',
        backgroundColor: '#1a1a2e',
        padding: { x: 5, y: 4 },
      })
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => {
        this.bet.numberBet = Math.max(0, this.bet.numberBet - 1)
        this.numberBetLabel.setText(` ${numberLabel(this.bet.numberBet)} `)
      })

    this.numberBetLabel = this.add
      .text(panelX + 140, curY, ` ${numberLabel(this.bet.numberBet)} `, {
        fontFamily: 'monospace',
        fontSize: '14px',
        color: accent,
        backgroundColor: '#1a1a2e',
        padding: { x: 5, y: 3 },
      })
      .setOrigin(0, 0)

    this.add
      .text(panelX + 180, curY, '[ + ]', {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: '#e2e8f0',
        backgroundColor: '#1a1a2e',
        padding: { x: 5, y: 4 },
      })
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => {
        this.bet.numberBet = Math.min(maxNumber, this.bet.numberBet + 1)
        this.numberBetLabel.setText(` ${numberLabel(this.bet.numberBet)} `)
      })

    curY += 32

    // ── BET AMOUNT ──
    sectionLabel('BET AMOUNT', curY)
    curY += 20

    this.add
      .text(panelX, curY, '[ BET - ]', {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: '#e2e8f0',
        backgroundColor: '#1a1a2e',
        padding: { x: 6, y: 4 },
      })
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => {
        this.bet.amount = Math.max(this.variant.minBet, this.bet.amount - 5)
        this.betAmountLabel.setText(` ${this.bet.amount} `)
      })

    this.betAmountLabel = this.add
      .text(panelX + 84, curY, ` ${this.bet.amount} `, {
        fontFamily: 'monospace',
        fontSize: '14px',
        color: accent,
        backgroundColor: '#1a1a2e',
        padding: { x: 5, y: 3 },
      })
      .setOrigin(0, 0)

    this.add
      .text(panelX + 130, curY, '[ BET + ]', {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: '#e2e8f0',
        backgroundColor: '#1a1a2e',
        padding: { x: 6, y: 4 },
      })
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => {
        this.bet.amount = Math.min(this.variant.maxBet, this.credits, this.bet.amount + 5)
        this.betAmountLabel.setText(` ${this.bet.amount} `)
      })

    curY += 40

    // ── SPIN button ──
    this.spinBtn = this.add
      .text(panelX + panelW * 0.4, curY, '[ SPIN ]', {
        fontFamily: 'monospace',
        fontSize: '16px',
        color: '#e2e8f0',
        backgroundColor: '#' + this.variant.primaryColor.toString(16).padStart(6, '0'),
        padding: { x: 20, y: 10 },
      })
      .setOrigin(0.5, 0)
      .setInteractive({ useHandCursor: true })
      .on('pointerover', () => { if (!this.spinning) this.spinBtn.setAlpha(0.8) })
      .on('pointerout', () => { if (!this.spinning) this.spinBtn.setAlpha(1) })
      .on('pointerdown', () => this.doSpin())

    void primary
  }

  // ─── Spin logic ──────────────────────────────────────────────────────────────

  private doSpin() {
    if (this.spinning) return
    if (!this.hasBet()) {
      this.resultLabel.setText('Place a bet first!')
      return
    }
    if (this.credits < this.bet.amount) {
      this.resultLabel.setText('Not enough credits!')
      return
    }

    this.spinning = true
    this.spinBtn.setAlpha(0.4).disableInteractive()
    this.resultLabel.setText('Spinning...')
    this.credits -= this.bet.amount
    this.updateCreditsLabel()

    const extraAngle = Phaser.Math.FloatBetween(Math.PI * 8, Math.PI * 20)
    const duration   = Phaser.Math.Between(2000, 3500)
    const targetDeg  = this.wheelGfx.angle + Phaser.Math.RadToDeg(extraAngle)

    this.tweens.add({
      targets: this.wheelGfx,
      angle: targetDeg,
      duration,
      ease: 'Cubic.easeOut',
      onComplete: () => {
        this.wheelAngle = Phaser.Math.DegToRad((this.wheelGfx.angle % 360 + 360) % 360)
        this.onSpinComplete()
      },
    })
  }

  private onSpinComplete() {
    const normalizedDeg = (this.wheelGfx.angle % 360 + 360) % 360
    const normalizedRad = Phaser.Math.DegToRad(normalizedDeg)
    const sliceAngle    = (Math.PI * 2) / this.totalSlots
    // Pointer sits at -π/2 (top). Wheel has rotated by normalizedRad clockwise.
    // The slot at the pointer is: slot at angle (3π/2 - normalizedRad) from slot-0 start.
    const pointerAngle = ((Math.PI * 2 * 1.5) - normalizedRad + Math.PI * 2 * 10) % (Math.PI * 2)
    const slotIndex    = Math.floor(pointerAngle / sliceAngle) % this.totalSlots
    const winNumber    = slotIndex

    const winFaction = numberToFaction(winNumber)
    const winLabel   = numberLabel(winNumber)

    let winnings = 0
    const messages: string[] = []

    // Number bet
    if (this.bet.useNumberBet && this.bet.numberBet === winNumber) {
      const payout = (this.variant.ruleKey === 'hdv' && winNumber === 38) ? 50 : 35
      const gain   = this.bet.amount * payout
      winnings += gain
      messages.push(`Number ${winLabel} hits! +${gain}`)
    }

    // Faction bet (pays 2:1, returns stake + 2× stake = 3× total)
    if (this.bet.faction !== null && winFaction !== 'HOUSE') {
      if (this.bet.faction === winFaction) {
        const gain = this.bet.amount * 2
        winnings  += gain
        messages.push(`FACTION ${winFaction} wins! +${gain}`)
      }
    }

    // Parity bet (0 / house → neither odd nor even)
    if (this.bet.parity !== null && winFaction !== 'HOUSE') {
      const isOdd = winNumber % 2 === 1
      const hit   = (this.bet.parity === 'ODD' && isOdd) || (this.bet.parity === 'EVEN' && !isOdd)
      if (hit) {
        winnings += this.bet.amount * 2
        messages.push(`PARITY ${this.bet.parity} wins! +${this.bet.amount * 2}`)
      }
    }

    // Tier bet
    if (this.bet.tier !== null && winFaction !== 'HOUSE') {
      const inTier =
        (this.bet.tier === 'LOW'  && winNumber >= 1  && winNumber <= 12) ||
        (this.bet.tier === 'MID'  && winNumber >= 13 && winNumber <= 24) ||
        (this.bet.tier === 'HIGH' && winNumber >= 25 && winNumber <= 36)
      if (inTier) {
        const gain = this.bet.amount * 3
        winnings  += gain
        messages.push(`TIER ${this.bet.tier} wins! +${gain}`)
      }
    }

    this.credits += winnings

    // HDV bonus spin on HOPE slot
    if (this.variant.ruleKey === 'hdv' && winNumber === 38) {
      this.resultLabel.setText(`✦ HOPE ✦ — bonus spin!\n${messages.join('\n') || 'No matching bets.'}`)
      this.updateCreditsLabel()
      this.spinning = false
      this.spinBtn.setAlpha(1).setInteractive({ useHandCursor: true })
      this.time.delayedCall(2000, () => this.triggerBonusSpin())
      return
    }

    const outcomeLabel = winFaction === 'HOUSE' ? 'HOUSE' : winFaction
    this.resultLabel.setText(
      `Number: ${winLabel}  —  ${outcomeLabel}\n${messages.join('\n') || 'No win this round.'}`,
    )
    this.updateCreditsLabel()
    this.spinning = false
    this.spinBtn.setAlpha(1).setInteractive({ useHandCursor: true })
  }

  private triggerBonusSpin() {
    // Refund bet cost so bonus spin is free
    this.credits += this.bet.amount
    this.updateCreditsLabel()
    this.resultLabel.setText('✦ BONUS SPIN! ✦')
    this.doSpin()
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  private hasBet(): boolean {
    return (
      this.bet.faction !== null ||
      this.bet.parity  !== null ||
      this.bet.tier    !== null ||
      this.bet.useNumberBet
    )
  }

  private updateCreditsLabel() {
    this.creditsLabel.setText(`CREDITS: ${this.credits}`)
  }

  private refreshBetHighlights() {
    const on  = '#' + this.variant.accentColor.toString(16).padStart(6, '0')
    const off = '#e2e8f0'

    this.factionBtns.forEach(({ label, text }) => {
      text.setColor(this.bet.faction === label ? on : off)
    })
    this.parityBtns.forEach(({ label, text }) => {
      text.setColor(this.bet.parity === label ? on : off)
    })
    this.tierBtns.forEach(({ label, text }) => {
      text.setColor(this.bet.tier === label ? on : off)
    })
    this.numberBetToggle.setColor(this.bet.useNumberBet ? on : off)
  }
}
