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

// Total-bet odds table: sum → payout multiplier (pay on top of stake)
const TOTAL_ODDS: Record<number, number> = {
  2: 29, 3: 14, 4: 9, 5: 7, 6: 5, 7: 4,
  8: 5, 9: 7, 10: 9, 11: 14, 12: 29,
}

type DiceFaceBet = 'TOTAL' | 'HIGH' | 'LOW' | 'DOUBLES' | 'FACTION_ODD' | 'FACTION_EVEN' | null

interface BetState {
  type: DiceFaceBet
  totalTarget: number   // for TOTAL bet
  amount: number
}

export class DiceScene extends Phaser.Scene {
  private variant!: GameVariantConfig
  private credits = 1000

  private die1 = 1
  private die2 = 1
  private die3 = 1   // only used for 'triple' ruleKey
  private rolling = false

  private creditsLabel!: Phaser.GameObjects.Text
  private die1Label!: Phaser.GameObjects.Text
  private die2Label!: Phaser.GameObjects.Text
  private die3Container!: Phaser.GameObjects.Container
  private die3Label!: Phaser.GameObjects.Text
  private resultLabel!: Phaser.GameObjects.Text
  private rollBtn!: Phaser.GameObjects.Text
  private betAmountLabel!: Phaser.GameObjects.Text
  private totalTargetLabel!: Phaser.GameObjects.Text

  private bet: BetState = { type: null, totalTarget: 7, amount: 10 }

  // Bet-type buttons for highlight toggling
  private betTypeBtns: { type: DiceFaceBet; text: Phaser.GameObjects.Text }[] = []
  private rollTimer!: Phaser.Time.TimerEvent

  constructor() {
    super({ key: 'DiceScene' })
  }

  init(data: { variant: GameVariantConfig }) {
    this.variant = data.variant ?? {
      id: 'dice_classic',
      name: 'FRACTURE DICE',
      primaryColor: 0x6366f1,
      accentColor: 0xf59e0b,
      ruleKey: 'classic',
      minBet: 5,
      maxBet: 500,
      houseEdge: 0.04,
    }
    this.credits  = 1000
    this.die1     = 1
    this.die2     = 1
    this.die3     = 1
    this.rolling  = false
    this.bet      = { type: null, totalTarget: 7, amount: Math.max(this.variant.minBet, 10) }
    this.betTypeBtns = []
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

    // Dice display center
    const diceY    = height * 0.4
    const die1X    = width * 0.35
    const die2X    = width * 0.58
    const die3X    = width * 0.8

    this.die1Label = this.buildDie(die1X, diceY, this.die1)
    this.die2Label = this.buildDie(die2X, diceY, this.die2)

    // Third die container (hidden unless 'triple' ruleKey reveals it after doubles)
    this.die3Container = this.add.container(die3X, diceY)
    const die3Gfx = this.add.graphics()
    die3Gfx.lineStyle(3, 0x4a4a6a, 0.4)
    die3Gfx.strokeRoundedRect(-40, -40, 80, 80, 12)
    die3Gfx.fillStyle(0x1a1a2e, 1)
    die3Gfx.fillRoundedRect(-40, -40, 80, 80, 12)
    this.die3Label = this.add
      .text(0, 0, '?', {
        fontFamily: 'monospace',
        fontSize: '28px',
        color: '#4a4a6a',
      })
      .setOrigin(0.5)
    this.die3Container.add([die3Gfx, this.die3Label])
    if (this.variant.ruleKey !== 'triple') {
      this.die3Container.setAlpha(0)
    }

    // Sum label
    this.resultLabel = this.add
      .text(width / 2, diceY + 70, '', {
        fontFamily: 'monospace',
        fontSize: '13px',
        color: '#e2e8f0',
        align: 'center',
        wordWrap: { width: width * 0.8 },
      })
      .setOrigin(0.5, 0)

    // Left side: bet panel
    this.buildBetPanel(width, height)

    // Right side: odds reference
    this.buildOddsPanel(width, height)

    this.updateCreditsLabel()
    this.refreshBetHighlights()
  }

  // ─── Die builder ─────────────────────────────────────────────────────────────

  private buildDie(cx: number, cy: number, value: number): Phaser.GameObjects.Text {
    const gfx = this.add.graphics()
    gfx.fillStyle(0x1a1a2e, 1)
    gfx.fillRoundedRect(cx - 40, cy - 40, 80, 80, 12)
    gfx.lineStyle(3, this.variant.primaryColor, 0.8)
    gfx.strokeRoundedRect(cx - 40, cy - 40, 80, 80, 12)

    return this.add
      .text(cx, cy, String(value), {
        fontFamily: 'monospace',
        fontSize: '36px',
        color: '#' + this.variant.accentColor.toString(16).padStart(6, '0'),
      })
      .setOrigin(0.5)
  }

  // ─── Bet panel ───────────────────────────────────────────────────────────────

  private buildBetPanel(width: number, height: number) {
    const panelX = width * 0.04
    const accent = '#' + this.variant.accentColor.toString(16).padStart(6, '0')
    let curY     = height * 0.18

    const label = (text: string, y: number) => {
      this.add.text(panelX, y, text, {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: '#6366f1',
        letterSpacing: 2,
      })
    }

    const makeBtn = (x: number, y: number, txt: string, type: DiceFaceBet): Phaser.GameObjects.Text => {
      const btn = this.add
        .text(x, y, txt, {
          fontFamily: 'monospace',
          fontSize: '11px',
          color: '#e2e8f0',
          backgroundColor: '#1a1a2e',
          padding: { x: 6, y: 5 },
        })
        .setInteractive({ useHandCursor: true })
        .on('pointerover', () => btn.setAlpha(0.8))
        .on('pointerout', () => btn.setAlpha(1))
        .on('pointerdown', () => {
          this.bet.type = this.bet.type === type ? null : type
          this.refreshBetHighlights()
        })
      if (type !== null) this.betTypeBtns.push({ type, text: btn })
      return btn
    }

    // ── TOTAL BET ──
    label('TOTAL BET', curY)
    curY += 18
    makeBtn(panelX, curY, '[ TARGET SUM ]', 'TOTAL')
    curY += 26

    // Target number selector
    this.add.text(panelX, curY, '[ - ]', {
      fontFamily: 'monospace',
      fontSize: '11px',
      color: '#e2e8f0',
      backgroundColor: '#1a1a2e',
      padding: { x: 6, y: 4 },
    })
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => {
        this.bet.totalTarget = Math.max(2, this.bet.totalTarget - 1)
        this.totalTargetLabel.setText(` ${this.bet.totalTarget} (${TOTAL_ODDS[this.bet.totalTarget]}:1) `)
      })

    this.totalTargetLabel = this.add
      .text(panelX + 40, curY, ` ${this.bet.totalTarget} (${TOTAL_ODDS[this.bet.totalTarget]}:1) `, {
        fontFamily: 'monospace',
        fontSize: '11px',
        color: accent,
        backgroundColor: '#1a1a2e',
        padding: { x: 5, y: 4 },
      })
      .setOrigin(0, 0)

    this.add.text(panelX + 165, curY, '[ + ]', {
      fontFamily: 'monospace',
      fontSize: '11px',
      color: '#e2e8f0',
      backgroundColor: '#1a1a2e',
      padding: { x: 6, y: 4 },
    })
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => {
        this.bet.totalTarget = Math.min(12, this.bet.totalTarget + 1)
        this.totalTargetLabel.setText(` ${this.bet.totalTarget} (${TOTAL_ODDS[this.bet.totalTarget]}:1) `)
      })

    curY += 30

    // ── HIGH / LOW ──
    label('HIGH / LOW  (1:1) — 7 = house', curY)
    curY += 18
    makeBtn(panelX, curY,      '[ HIGH 8-12 ]', 'HIGH')
    makeBtn(panelX + 100, curY, '[ LOW 2-6 ]',  'LOW')
    curY += 30

    // ── DOUBLES ──
    label('DOUBLES  (5:1)', curY)
    curY += 18
    makeBtn(panelX, curY, '[ DOUBLES ]', 'DOUBLES')
    curY += 30

    // ── FACTION / PARITY ──
    label('FACTION BET  (1:1)', curY)
    curY += 18
    makeBtn(panelX, curY,     '[ SOVEREIGN\n  (odd sum) ]',  'FACTION_ODD')
    makeBtn(panelX + 115, curY, '[ VEILED\n  (even sum) ]', 'FACTION_EVEN')
    curY += 52

    // ── BET AMOUNT ──
    label('BET AMOUNT', curY)
    curY += 18

    this.add.text(panelX, curY, '[ BET - ]', {
      fontFamily: 'monospace',
      fontSize: '11px',
      color: '#e2e8f0',
      backgroundColor: '#1a1a2e',
      padding: { x: 6, y: 5 },
    })
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => {
        this.bet.amount = Math.max(this.variant.minBet, this.bet.amount - 5)
        this.betAmountLabel.setText(` ${this.bet.amount} `)
      })

    this.betAmountLabel = this.add
      .text(panelX + 80, curY, ` ${this.bet.amount} `, {
        fontFamily: 'monospace',
        fontSize: '14px',
        color: accent,
        backgroundColor: '#1a1a2e',
        padding: { x: 5, y: 4 },
      })
      .setOrigin(0, 0)

    this.add.text(panelX + 125, curY, '[ BET + ]', {
      fontFamily: 'monospace',
      fontSize: '11px',
      color: '#e2e8f0',
      backgroundColor: '#1a1a2e',
      padding: { x: 6, y: 5 },
    })
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => {
        this.bet.amount = Math.min(this.variant.maxBet, this.credits, this.bet.amount + 5)
        this.betAmountLabel.setText(` ${this.bet.amount} `)
      })

    curY += 40

    // ── ROLL ──
    this.rollBtn = this.add
      .text(panelX + 100, curY, '[ ROLL ]', {
        fontFamily: 'monospace',
        fontSize: '16px',
        color: '#e2e8f0',
        backgroundColor: '#' + this.variant.primaryColor.toString(16).padStart(6, '0'),
        padding: { x: 16, y: 10 },
      })
      .setOrigin(0.5, 0)
      .setInteractive({ useHandCursor: true })
      .on('pointerover', () => { if (!this.rolling) this.rollBtn.setAlpha(0.8) })
      .on('pointerout', () => { if (!this.rolling) this.rollBtn.setAlpha(1) })
      .on('pointerdown', () => this.doRoll())
  }

  private buildOddsPanel(width: number, height: number) {
    const panelX = width * 0.78
    let curY     = height * 0.18

    this.add.text(panelX, curY, 'TOTAL ODDS', {
      fontFamily: 'monospace',
      fontSize: '10px',
      color: '#6366f1',
      letterSpacing: 2,
    })
    curY += 16

    for (let sum = 2; sum <= 12; sum++) {
      this.add.text(panelX, curY, `${String(sum).padStart(2, ' ')}  →  ${TOTAL_ODDS[sum]}:1`, {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: sum === 7 ? '#f59e0b' : '#94a3b8',
      })
      curY += 14
    }
  }

  // ─── Roll logic ───────────────────────────────────────────────────────────────

  private doRoll() {
    if (this.rolling) return
    if (this.bet.type === null) {
      this.resultLabel.setText('Select a bet type first!')
      return
    }
    if (this.credits < this.bet.amount) {
      this.resultLabel.setText('Not enough credits!')
      return
    }

    this.rolling = true
    this.rollBtn.setAlpha(0.4).disableInteractive()
    this.resultLabel.setText('Rolling...')
    this.credits -= this.bet.amount
    this.updateCreditsLabel()

    // Third die hidden again at start of each roll
    if (this.variant.ruleKey === 'triple') {
      this.die3Label.setText('?').setColor('#4a4a6a')
      this.die3Container.setAlpha(1)
    }

    // Flash random values for ~800ms then settle
    let flashes = 0
    const maxFlashes = 16
    this.rollTimer = this.time.addEvent({
      delay: 50,
      loop: true,
      callback: () => {
        flashes++
        this.die1Label.setText(String(Phaser.Math.Between(1, 6)))
        this.die2Label.setText(String(Phaser.Math.Between(1, 6)))
        if (this.variant.ruleKey === 'triple') {
          this.die3Label.setText(String(Phaser.Math.Between(1, 6)))
        }
        if (flashes >= maxFlashes) {
          this.rollTimer.remove(false)
          this.settleRoll()
        }
      },
    })
  }

  private settleRoll() {
    this.die1 = Phaser.Math.Between(1, 6)
    this.die2 = Phaser.Math.Between(1, 6)
    this.die3 = Phaser.Math.Between(1, 6)

    this.die1Label.setText(String(this.die1))
    this.die2Label.setText(String(this.die2))

    const sum     = this.die1 + this.die2
    const isDouble = this.die1 === this.die2

    // Handle triple ruleKey
    let tripleActive = false
    if (this.variant.ruleKey === 'triple') {
      if (isDouble) {
        // Reveal third die
        this.die3Label.setText(String(this.die3))
          .setColor('#' + this.variant.accentColor.toString(16).padStart(6, '0'))
        if (this.die3 === this.die1) tripleActive = true
      } else {
        this.die3Label.setText('—').setColor('#4a4a6a')
      }
    }

    const winnings = this.computeWinnings(sum, isDouble, tripleActive)
    this.credits  += winnings

    this.resultLabel.setText(this.buildResultText(sum, isDouble, tripleActive, winnings))
    this.updateCreditsLabel()

    this.rolling = false
    this.rollBtn.setAlpha(1).setInteractive({ useHandCursor: true })
  }

  private computeWinnings(sum: number, isDouble: boolean, tripleActive: boolean): number {
    const { type, totalTarget, amount } = this.bet

    if (type === 'TOTAL') {
      if (sum === totalTarget) return amount * (TOTAL_ODDS[totalTarget] + 1)
      return 0
    }

    if (type === 'HIGH') {
      if (sum >= 8 && sum <= 12) return amount * 2
      return 0
    }

    if (type === 'LOW') {
      if (sum >= 2 && sum <= 6) return amount * 2
      return 0
      // 7 = house wins (no return)
    }

    if (type === 'DOUBLES') {
      if (tripleActive && this.variant.ruleKey === 'triple') return amount * 26   // 25:1
      if (isDouble) return amount * 6   // 5:1
      return 0
    }

    if (type === 'FACTION_ODD') {
      if (sum % 2 === 1) {
        // faction_bonus: all-odd dice face values give 2x
        if (this.variant.ruleKey === 'faction_bonus' && this.die1 % 2 === 1 && this.die2 % 2 === 1) {
          return amount * 4
        }
        return amount * 2
      }
      return 0
    }

    if (type === 'FACTION_EVEN') {
      if (sum % 2 === 0) {
        // faction_bonus: all-even dice face values give 2x
        if (this.variant.ruleKey === 'faction_bonus' && this.die1 % 2 === 0 && this.die2 % 2 === 0) {
          return amount * 4
        }
        return amount * 2
      }
      return 0
    }

    return 0
  }

  private buildResultText(sum: number, isDouble: boolean, tripleActive: boolean, winnings: number): string {
    const { type, totalTarget } = this.bet
    const rollDesc = `You rolled ${this.die1} + ${this.die2} = ${sum}`

    if (winnings > 0) {
      let betName = ''
      if (type === 'TOTAL')        betName = `SUM ${totalTarget}`
      else if (type === 'HIGH')    betName = 'HIGH'
      else if (type === 'LOW')     betName = 'LOW'
      else if (type === 'DOUBLES') betName = tripleActive ? 'TRIPLE DOUBLES' : 'DOUBLES'
      else if (type === 'FACTION_ODD')  betName = 'SOVEREIGN (odd)'
      else if (type === 'FACTION_EVEN') betName = 'VEILED (even)'

      const bonusNote = (this.variant.ruleKey === 'faction_bonus' && winnings === this.bet.amount * 4)
        ? ' (faction bonus ×2!)' : ''

      return `${rollDesc} — ${betName} hits!${bonusNote}  +${winnings} credits`
    }

    const doubleNote = isDouble ? `  Doubles rolled!` : ''
    return `${rollDesc}${doubleNote} — No win.`
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  private updateCreditsLabel() {
    this.creditsLabel.setText(`CREDITS: ${this.credits}`)
  }

  private refreshBetHighlights() {
    const on  = '#' + this.variant.accentColor.toString(16).padStart(6, '0')
    const off = '#e2e8f0'
    this.betTypeBtns.forEach(({ type, text }) => {
      text.setColor(this.bet.type === type ? on : off)
    })
  }
}
