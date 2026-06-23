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

// ── Card types ───────────────────────────────────────────────────────────────

type Suit = '♠' | '♥' | '♦' | '♣' | 'HOPE'
type Rank = 'A' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' | '10' | 'J' | 'Q' | 'K'

interface Card {
  rank: Rank
  suit: Suit
  isHope: boolean
  faceDown: boolean
}

type GamePhase = 'betting' | 'player' | 'dealer' | 'result'
type RoundResult = 'win' | 'blackjack' | 'bust' | 'push' | 'dealerBust' | 'surrender'

// ── Suit faction colours ─────────────────────────────────────────────────────

const SUIT_COLOR: Record<Suit, number> = {
  '♠': 0x6366f1,   // Sovereign Crown
  '♥': 0x22c55e,   // Veiled Current
  '♦': 0xf59e0b,   // Wildlands
  '♣': 0x94a3b8,   // Factionless
  'HOPE': 0xa855f7, // Hope
}

const RANKS: Rank[] = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
const SUITS: Suit[] = ['♠', '♥', '♦', '♣']

// ── Helpers ───────────────────────────────────────────────────────────────────

function hexToRgbString(hex: number): string {
  return '#' + hex.toString(16).padStart(6, '0')
}

function cardValue(rank: Rank): number {
  if (['J', 'Q', 'K'].includes(rank)) return 10
  if (rank === 'A') return 11
  return parseInt(rank, 10)
}

function buildDeck(): Card[] {
  const deck: Card[] = []
  for (const suit of SUITS) {
    for (const rank of RANKS) {
      deck.push({ rank, suit, isHope: false, faceDown: false })
    }
  }
  // Shuffle in one HOPE card
  deck.push({ rank: 'A', suit: 'HOPE', isHope: true, faceDown: false })
  return deck
}

function shuffle(deck: Card[]): Card[] {
  const d = [...deck]
  for (let i = d.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    const tmp = d[i]
    d[i] = d[j]
    d[j] = tmp
  }
  return d
}

function handTotal(hand: Card[], hopePicked: number | null): number {
  let total = 0
  let aces = 0

  for (const card of hand) {
    if (card.faceDown) continue
    if (card.isHope) {
      // Use the chosen value, or default 11 if not yet decided
      total += hopePicked ?? 11
      continue
    }
    const v = cardValue(card.rank)
    if (card.rank === 'A') aces++
    total += v
  }

  // Soft ace reduction
  while (total > 21 && aces > 0) {
    total -= 10
    aces--
  }

  return total
}

function isBlackjack(hand: Card[]): boolean {
  if (hand.length !== 2) return false
  const vals = hand.map((c) => (c.isHope ? 11 : cardValue(c.rank)))
  return vals.includes(11) && vals.includes(10)
}

// ── Scene ─────────────────────────────────────────────────────────────────────

export class BlackjackScene extends Phaser.Scene {
  private variant!: GameVariantConfig
  private deck: Card[] = []
  private playerHand: Card[] = []
  private dealerHand: Card[] = []
  private hopePicked: number | null = null

  private credits = 1000
  private bet = 10
  private phase: GamePhase = 'betting'
  private winStreak = 0
  private doubledDown = false

  // Card container lists
  private playerCardObjects: Phaser.GameObjects.Container[] = []
  private dealerCardObjects: Phaser.GameObjects.Container[] = []

  // UI text refs
  private creditText!: Phaser.GameObjects.Text
  private betText!: Phaser.GameObjects.Text
  private playerScoreText!: Phaser.GameObjects.Text
  private dealerScoreText!: Phaser.GameObjects.Text
  private statusText!: Phaser.GameObjects.Text

  // Action buttons (kept in named map for targeted enable/disable)
  private btnHit!: Phaser.GameObjects.Text
  private btnStand!: Phaser.GameObjects.Text
  private btnDouble!: Phaser.GameObjects.Text
  private btnSurrender!: Phaser.GameObjects.Text
  private btnDeal!: Phaser.GameObjects.Text
  private btnBetDown!: Phaser.GameObjects.Text
  private btnBetUp!: Phaser.GameObjects.Text

  // Hope popup buttons (shown only when HOPE card is drawn)
  private hopePopup!: Phaser.GameObjects.Container

  // Layout constants (set in create)
  private dealerCardY = 0
  private playerCardY = 0
  private cardStartX = 0

  // Card width/height
  private static readonly CARD_W = 60
  private static readonly CARD_H = 90

  constructor() {
    super({ key: 'BlackjackScene' })
  }

  init(data: { variant: GameVariantConfig }) {
    this.variant = data.variant
    this.credits = 1000
    this.bet = Math.max(data.variant.minBet, 10)
    this.phase = 'betting'
    this.winStreak = 0
    this.doubledDown = false
    this.hopePicked = null
    this.deck = shuffle(buildDeck())
    this.playerHand = []
    this.dealerHand = []
    this.playerCardObjects = []
    this.dealerCardObjects = []
  }

  create() {
    const { width, height } = this.cameras.main
    const primaryHex = hexToRgbString(this.variant.primaryColor)
    const accentHex = hexToRgbString(this.variant.accentColor)
    const glowHex = hexToRgbString(FACTIONS['veiled_current']?.colorScheme.glowHex ?? 0x6366f1)

    this.dealerCardY = height * 0.25
    this.playerCardY = height * 0.62
    this.cardStartX = width / 2 - (BlackjackScene.CARD_W + 12) * 2.5

    // Background
    this.add.rectangle(width / 2, height / 2, width, height, 0x0f0f1a)

    // Felt zones
    this.add
      .rectangle(width / 2, height * 0.27, width * 0.88, height * 0.3, 0x1a1a2e)
      .setStrokeStyle(1, this.variant.primaryColor, 0.4)
    this.add
      .rectangle(width / 2, height * 0.64, width * 0.88, height * 0.3, 0x1a1a2e)
      .setStrokeStyle(1, this.variant.accentColor, 0.4)

    // ── Title ──────────────────────────────────────────────────────────────
    this.add
      .text(width / 2, height * 0.05, this.variant.name.toUpperCase(), {
        fontFamily: 'monospace',
        fontSize: '20px',
        color: primaryHex,
        letterSpacing: 4,
      })
      .setOrigin(0.5)

    // Dealer / player zone labels
    this.add
      .text(width * 0.08, height * 0.13, 'DEALER', {
        fontFamily: 'monospace',
        fontSize: '11px',
        color: '#4a4a6a',
        letterSpacing: 2,
      })

    this.add
      .text(width * 0.08, height * 0.5, 'YOU', {
        fontFamily: 'monospace',
        fontSize: '11px',
        color: '#4a4a6a',
        letterSpacing: 2,
      })

    // Score labels
    this.dealerScoreText = this.add
      .text(width * 0.93, height * 0.13, 'DEALER: ?', {
        fontFamily: 'monospace',
        fontSize: '13px',
        color: '#94a3b8',
      })
      .setOrigin(1, 0)

    this.playerScoreText = this.add
      .text(width * 0.93, height * 0.5, 'YOU: 0', {
        fontFamily: 'monospace',
        fontSize: '13px',
        color: '#94a3b8',
      })
      .setOrigin(1, 0)

    // Status text
    this.statusText = this.add
      .text(width / 2, height * 0.44, '', {
        fontFamily: 'monospace',
        fontSize: '22px',
        color: accentHex,
        letterSpacing: 4,
      })
      .setOrigin(0.5)

    // ── HUD ────────────────────────────────────────────────────────────────
    this.betText = this.add.text(width * 0.07, height * 0.87, '', {
      fontFamily: 'monospace',
      fontSize: '13px',
      color: '#94a3b8',
    })

    this.creditText = this.add
      .text(width * 0.93, height * 0.87, '', {
        fontFamily: 'monospace',
        fontSize: '13px',
        color: '#94a3b8',
      })
      .setOrigin(1, 0)

    this.refreshHUD()

    // ── Action buttons ─────────────────────────────────────────────────────
    this.btnBetDown = this.makeButton(width * 0.15, height * 0.92, 'BET -', 0x475569, () => this.adjustBet(-1))
    this.btnBetUp   = this.makeButton(width * 0.3,  height * 0.92, 'BET +', 0x475569, () => this.adjustBet(1))
    this.btnDeal    = this.makeButton(width * 0.5,  height * 0.92, 'DEAL',  this.variant.primaryColor, () => this.startDeal())
    this.btnHit     = this.makeButton(width * 0.3,  height * 0.92, 'HIT',   0x22c55e, () => this.playerHit())
    this.btnStand   = this.makeButton(width * 0.5,  height * 0.92, 'STAND', 0x6366f1, () => this.playerStand())
    this.btnDouble  = this.makeButton(width * 0.7,  height * 0.92, 'DOUBLE', 0xf59e0b, () => this.playerDouble())
    this.btnSurrender = this.makeButton(width * 0.85, height * 0.92, 'SURRENDER', 0x6b7280, () => this.playerSurrender())

    // ── Hope popup (hidden until needed) ──────────────────────────────────
    this.hopePopup = this.buildHopePopup(width, height)
    this.hopePopup.setVisible(false)

    // Show betting phase UI
    this.showBettingPhase()

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

  // ── Button factory ───────────────────────────────────────────────────────

  private makeButton(
    x: number,
    y: number,
    label: string,
    color: number,
    handler: () => void,
  ): Phaser.GameObjects.Text {
    const btn = this.add
      .text(x, y, `[ ${label} ]`, {
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
    btn.on('pointerdown', handler)

    return btn
  }

  // ── Hope popup ───────────────────────────────────────────────────────────

  private buildHopePopup(width: number, height: number): Phaser.GameObjects.Container {
    const bg = this.add.rectangle(0, 0, 280, 140, 0x1a1a2e).setStrokeStyle(2, 0xa855f7, 0.9)
    const label = this.add
      .text(0, -38, 'HOPE CARD — Choose value:', {
        fontFamily: 'monospace',
        fontSize: '13px',
        color: '#a855f7',
      })
      .setOrigin(0.5)

    const btn1 = this.add
      .text(-50, 8, '[ 1 ]', {
        fontFamily: 'monospace',
        fontSize: '18px',
        color: '#e2e8f0',
        backgroundColor: '#7c3aed',
        padding: { x: 18, y: 10 },
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => this.resolveHopeCard(1))

    const btn11 = this.add
      .text(50, 8, '[ 11 ]', {
        fontFamily: 'monospace',
        fontSize: '18px',
        color: '#e2e8f0',
        backgroundColor: '#7c3aed',
        padding: { x: 18, y: 10 },
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => this.resolveHopeCard(11))

    const container = this.add.container(width / 2, height * 0.44, [bg, label, btn1, btn11])
    return container
  }

  // ── Phase management ─────────────────────────────────────────────────────

  private showBettingPhase() {
    this.phase = 'betting'
    this.statusText.setText('')

    this.btnBetDown.setVisible(true).setAlpha(1).setInteractive({ useHandCursor: true })
    this.btnBetUp.setVisible(true).setAlpha(1).setInteractive({ useHandCursor: true })
    this.btnDeal.setVisible(true).setAlpha(1).setInteractive({ useHandCursor: true })

    this.btnHit.setVisible(false)
    this.btnStand.setVisible(false)
    this.btnDouble.setVisible(false)
    this.btnSurrender.setVisible(false)
  }

  private showPlayerPhase() {
    this.phase = 'player'

    this.btnBetDown.setVisible(false)
    this.btnBetUp.setVisible(false)
    this.btnDeal.setVisible(false)

    this.btnHit.setVisible(true).setAlpha(1).setInteractive({ useHandCursor: true })
    this.btnStand.setVisible(true).setAlpha(1).setInteractive({ useHandCursor: true })

    // DOUBLE only on first 2 cards with enough credits
    const canDouble = this.playerHand.length === 2 && this.credits >= this.bet
    this.btnDouble.setVisible(true)
    if (canDouble) {
      this.btnDouble.setAlpha(1).setInteractive({ useHandCursor: true })
    } else {
      this.btnDouble.setAlpha(0.35).disableInteractive()
    }

    // SURRENDER: only on first 2 cards, only if ruleKey is 'surrender'
    const canSurrender = this.variant.ruleKey === 'surrender' && this.playerHand.length === 2
    this.btnSurrender.setVisible(canSurrender)
    if (canSurrender) {
      this.btnSurrender.setAlpha(1).setInteractive({ useHandCursor: true })
    }
  }

  private hideAllActionButtons() {
    ;[this.btnHit, this.btnStand, this.btnDouble, this.btnSurrender,
      this.btnDeal, this.btnBetDown, this.btnBetUp].forEach((b) => {
      b.setVisible(false)
    })
  }

  // ── Deal flow ────────────────────────────────────────────────────────────

  private startDeal() {
    if (this.credits < this.bet) {
      this.statusText.setText('NOT ENOUGH CREDITS').setColor('#ef4444')
      return
    }

    // Clear existing card objects
    this.clearCardObjects()

    this.credits -= this.bet
    this.doubledDown = false
    this.hopePicked = null

    if (this.deck.length < 10) this.deck = shuffle(buildDeck())

    this.playerHand = []
    this.dealerHand = []

    // Deal: player, dealer, player, dealer (dealer 2nd card face-down)
    this.playerHand.push({ ...this.drawCard(), faceDown: false })
    this.dealerHand.push({ ...this.drawCard(), faceDown: false })
    this.playerHand.push({ ...this.drawCard(), faceDown: false })
    this.dealerHand.push({ ...this.drawCard(), faceDown: true })

    this.renderHands()
    this.refreshHUD()

    // Check for HOPE card in player's hand immediately
    const playerHopeIdx = this.playerHand.findIndex((c) => c.isHope)
    if (playerHopeIdx !== -1) {
      this.showHopePopup()
      return
    }

    // Check immediate blackjack
    if (isBlackjack(this.playerHand)) {
      this.resolveRound('blackjack')
      return
    }

    this.showPlayerPhase()
    this.updateScoreLabels()
  }

  private drawCard(): Card {
    const card = this.deck.pop()
    if (!card) {
      this.deck = shuffle(buildDeck())
      return this.deck.pop()!
    }
    return card
  }

  // ── Player actions ───────────────────────────────────────────────────────

  private playerHit() {
    if (this.phase !== 'player') return

    const card = { ...this.drawCard(), faceDown: false }
    this.playerHand.push(card)
    this.renderHands()

    if (card.isHope) {
      this.showHopePopup()
      return
    }

    const total = handTotal(this.playerHand, this.hopePicked)
    this.updateScoreLabels()

    if (total > 21) {
      this.resolveRound('bust')
    } else {
      // After first HIT, double is no longer available
      this.showPlayerPhase()
    }
  }

  private playerStand() {
    if (this.phase !== 'player') return
    this.runDealerTurn()
  }

  private playerDouble() {
    if (this.phase !== 'player') return
    if (this.playerHand.length !== 2 || this.credits < this.bet) return

    this.credits -= this.bet
    this.bet *= 2
    this.doubledDown = true
    this.refreshHUD()

    const card = { ...this.drawCard(), faceDown: false }
    this.playerHand.push(card)
    this.renderHands()

    if (card.isHope) {
      this.showHopePopup()
      return
    }

    const total = handTotal(this.playerHand, this.hopePicked)
    this.updateScoreLabels()

    if (total > 21) {
      this.resolveRound('bust')
    } else {
      this.runDealerTurn()
    }
  }

  private playerSurrender() {
    if (this.phase !== 'player') return
    this.resolveRound('surrender')
  }

  // ── HOPE card popup ──────────────────────────────────────────────────────

  private showHopePopup() {
    this.hopePopup.setVisible(true)
    this.hideAllActionButtons()

    // Purple flash
    this.cameras.main.flash(300, 168, 85, 247, false)
  }

  private resolveHopeCard(value: 1 | 11) {
    this.hopePicked = value
    this.hopePopup.setVisible(false)

    const total = handTotal(this.playerHand, this.hopePicked)
    this.updateScoreLabels()

    if (total > 21) {
      this.resolveRound('bust')
      return
    }

    if (isBlackjack(this.playerHand)) {
      this.resolveRound('blackjack')
      return
    }

    this.showPlayerPhase()
  }

  // ── Dealer turn ──────────────────────────────────────────────────────────

  private runDealerTurn() {
    this.phase = 'dealer'
    this.hideAllActionButtons()

    // Reveal the face-down card
    this.dealerHand.forEach((c) => { c.faceDown = false })
    this.renderHands()
    this.updateScoreLabels()

    const dealerDraw = () => {
      const total = handTotal(this.dealerHand, null)
      if (total < 17) {
        this.time.delayedCall(600, () => {
          this.dealerHand.push({ ...this.drawCard(), faceDown: false })
          this.renderHands()
          this.updateScoreLabels()
          dealerDraw()
        })
      } else {
        this.time.delayedCall(300, () => this.resolveResult())
      }
    }

    this.time.delayedCall(400, dealerDraw)
  }

  // ── Resolution ───────────────────────────────────────────────────────────

  private resolveRound(outcome: RoundResult) {
    this.phase = 'result'
    this.hideAllActionButtons()

    // Reveal dealer cards for any outcome
    this.dealerHand.forEach((c) => { c.faceDown = false })
    this.renderHands()
    this.updateScoreLabels()

    this.applyOutcome(outcome)
  }

  private resolveResult() {
    const playerTotal = handTotal(this.playerHand, this.hopePicked)
    const dealerTotal = handTotal(this.dealerHand, null)

    if (dealerTotal > 21) {
      this.resolveRound('dealerBust')
    } else if (playerTotal > dealerTotal) {
      this.resolveRound('win')
    } else if (playerTotal === dealerTotal) {
      this.resolveRound('push')
    } else {
      this.resolveRound('bust')
    }
  }

  private applyOutcome(outcome: RoundResult) {
    let payout = 0
    let statusMsg = ''
    let statusColor = '#e2e8f0'

    switch (outcome) {
      case 'blackjack':
        payout = Math.floor(this.bet * 2.5)
        statusMsg = 'BLACKJACK!'
        statusColor = '#a855f7'
        this.winStreak++
        break
      case 'win':
      case 'dealerBust':
        payout = this.bet * 2
        statusMsg = outcome === 'dealerBust' ? 'DEALER BUSTS!' : 'WIN!'
        statusColor = '#22c55e'
        this.winStreak++
        break
      case 'push':
        payout = this.bet
        statusMsg = 'PUSH'
        statusColor = '#6b7280'
        // streak unbroken on push for progressive
        break
      case 'bust':
        payout = 0
        statusMsg = 'BUST'
        statusColor = '#ef4444'
        this.winStreak = 0
        break
      case 'surrender':
        payout = Math.floor(this.bet / 2)
        statusMsg = 'SURRENDER — half bet returned'
        statusColor = '#6b7280'
        this.winStreak = 0
        break
    }

    // Progressive bonus: 3+ win streak gives 1.5× on win payouts
    if (this.variant.ruleKey === 'progressive' && this.winStreak >= 3 && payout > this.bet) {
      payout = Math.floor(payout * 1.5)
      statusMsg += `  ×1.5 STREAK`
    }

    this.credits += payout
    this.refreshHUD()

    this.statusText.setText(statusMsg).setColor(statusColor)
    this.tweens.add({
      targets: this.statusText,
      alpha: 0,
      duration: 200,
      yoyo: true,
      repeat: 2,
      onComplete: () => { this.statusText.setAlpha(1) },
    })

    // Restore real bet if doubled
    if (this.doubledDown) this.bet = Math.floor(this.bet / 2)

    this.time.delayedCall(1800, () => this.showBettingPhase())
  }

  // ── Card rendering ───────────────────────────────────────────────────────

  private clearCardObjects() {
    this.playerCardObjects.forEach((c) => c.destroy())
    this.dealerCardObjects.forEach((c) => c.destroy())
    this.playerCardObjects = []
    this.dealerCardObjects = []
  }

  private renderHands() {
    this.clearCardObjects()
    this.dealerHand.forEach((card, i) => {
      const obj = this.buildCard(card, this.cardStartX + i * (BlackjackScene.CARD_W + 12), this.dealerCardY)
      this.dealerCardObjects.push(obj)
    })
    this.playerHand.forEach((card, i) => {
      const obj = this.buildCard(card, this.cardStartX + i * (BlackjackScene.CARD_W + 12), this.playerCardY)
      this.playerCardObjects.push(obj)
    })
  }

  private buildCard(card: Card, x: number, y: number): Phaser.GameObjects.Container {
    const W = BlackjackScene.CARD_W
    const H = BlackjackScene.CARD_H

    if (card.faceDown) {
      const bg = this.add.rectangle(0, 0, W, H, 0x1a1a2e).setStrokeStyle(2, this.variant.primaryColor, 0.6)
      const back = this.add
        .text(0, 0, '▪▪▪', { fontFamily: 'monospace', fontSize: '14px', color: '#4a4a6a' })
        .setOrigin(0.5)
      const container = this.add.container(x, y, [bg, back])
      return container
    }

    const suitColor = SUIT_COLOR[card.suit]
    const suitColorHex = hexToRgbString(suitColor)
    const bgColor = card.isHope ? 0x2d1b4e : 0x1a1a2e
    const borderColor = card.isHope ? 0xa855f7 : suitColor

    const bg = this.add.rectangle(0, 0, W, H, bgColor).setStrokeStyle(2, borderColor, 0.8)

    const rankTop = this.add
      .text(-W / 2 + 6, -H / 2 + 6, card.rank, {
        fontFamily: 'monospace',
        fontSize: '12px',
        color: suitColorHex,
      })
      .setOrigin(0, 0)

    const suitCenter = this.add
      .text(0, 0, card.suit === 'HOPE' ? '✧' : card.suit, {
        fontFamily: 'monospace',
        fontSize: '22px',
        color: suitColorHex,
      })
      .setOrigin(0.5)

    const valBottom = this.add
      .text(W / 2 - 6, H / 2 - 6, card.isHope ? '?' : String(cardValue(card.rank)), {
        fontFamily: 'monospace',
        fontSize: '10px',
        color: '#4a4a6a',
      })
      .setOrigin(1, 1)

    const children: Phaser.GameObjects.GameObject[] = [bg, rankTop, suitCenter, valBottom]

    if (card.isHope) {
      const hopeLbl = this.add
        .text(0, H / 2 - 16, 'HOPE', {
          fontFamily: 'monospace',
          fontSize: '8px',
          color: '#a855f7',
        })
        .setOrigin(0.5, 1)
      children.push(hopeLbl)
    }

    const container = this.add.container(x, y, children)
    return container
  }

  // ── Score labels ─────────────────────────────────────────────────────────

  private updateScoreLabels() {
    const playerTotal = handTotal(this.playerHand, this.hopePicked)

    const visibleDealer = this.dealerHand.filter((c) => !c.faceDown)
    const dealerVisible = visibleDealer.length > 0
      ? handTotal(this.dealerHand.filter((c) => !c.faceDown), null)
      : 0
    const dealerHasFaceDown = this.dealerHand.some((c) => c.faceDown)

    this.playerScoreText.setText(`YOU: ${playerTotal}`)
    this.dealerScoreText.setText(dealerHasFaceDown ? `DEALER: ${dealerVisible}+?` : `DEALER: ${handTotal(this.dealerHand, null)}`)
  }

  // ── HUD ──────────────────────────────────────────────────────────────────

  private refreshHUD() {
    this.betText.setText(`BET: ${this.bet}`)
    this.creditText.setText(`CREDITS: ${this.credits}`)
  }

  private adjustBet(dir: 1 | -1) {
    if (this.phase !== 'betting') return
    const step = this.variant.minBet
    this.bet = Phaser.Math.Clamp(this.bet + dir * step, this.variant.minBet, Math.min(this.variant.maxBet, this.credits))
    this.refreshHUD()
  }
}
