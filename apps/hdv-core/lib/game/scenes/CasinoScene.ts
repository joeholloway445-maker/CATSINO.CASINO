import Phaser from 'phaser'
import {
  ALL_GAMES,
  getGamesByCategory,
  getHotGames,
  GAME_CATALOGUE_SIZE,
  type GameCategory,
  type GameVariantConfig,
} from '@/lib/game/data/gameFactory'

const CATEGORIES: { key: GameCategory | 'hot'; label: string; color: number }[] = [
  { key: 'hot',       label: '🔥 HOT',      color: 0xf59e0b },
  { key: 'slots',     label: '🎰 SLOTS',     color: 0xa855f7 },
  { key: 'blackjack', label: '🃏 BLACKJACK', color: 0x22c55e },
  { key: 'roulette',  label: '⚪ ROULETTE',  color: 0x6366f1 },
  { key: 'crash',     label: '📈 CRASH',     color: 0xef4444 },
  { key: 'dice',      label: '🎲 DICE',      color: 0xf97316 },
  { key: 'racing',    label: '🏁 RACING',    color: 0x38bdf8 },
  { key: 'sports',    label: '⚔ SPORTS',     color: 0xfb923c },
  { key: 'arcade',    label: '🕹 ARCADE',    color: 0x4ade80 },
]

const CARDS_PER_PAGE = 6

interface GameCard {
  container: Phaser.GameObjects.Container
  game: GameVariantConfig
}

export class CasinoScene extends Phaser.Scene {
  private activeCategory: GameCategory | 'hot' = 'hot'
  private currentPage = 0
  private cardPool: GameCard[] = []
  private pageLabel!: Phaser.GameObjects.Text
  private prevBtn!: Phaser.GameObjects.Text
  private nextBtn!: Phaser.GameObjects.Text
  private categoryBtns: Phaser.GameObjects.Text[] = []

  constructor() {
    super({ key: 'CasinoScene' })
  }

  create() {
    const { width, height } = this.cameras.main

    this.add.rectangle(width / 2, height / 2, width, height, 0x050510)

    // Title
    this.add
      .text(width / 2, height * 0.06, 'PAWS VEGAS', {
        fontFamily: 'monospace',
        fontSize: '28px',
        color: '#f59e0b',
        letterSpacing: 6,
      })
      .setOrigin(0.5)

    this.add
      .text(width / 2, height * 0.12, `${GAME_CATALOGUE_SIZE} GAMES AVAILABLE`, {
        fontFamily: 'monospace',
        fontSize: '11px',
        color: '#6b7280',
        letterSpacing: 2,
      })
      .setOrigin(0.5)

    // Back button
    this.add
      .text(40, 36, '← MODES', {
        fontFamily: 'monospace',
        fontSize: '13px',
        color: '#6366f1',
      })
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => this.scene.start('ModeSelectorScene'))

    // Category filter bar
    const catSpacing = width / (CATEGORIES.length + 1)
    CATEGORIES.forEach(({ key, label, color }, i) => {
      const btn = this.add
        .text(catSpacing * (i + 1), height * 0.2, label, {
          fontFamily: 'monospace',
          fontSize: '11px',
          color: '#94a3b8',
          padding: { x: 8, y: 4 },
        })
        .setOrigin(0.5)
        .setInteractive({ useHandCursor: true })

      btn.on('pointerdown', () => {
        this.activeCategory = key
        this.currentPage = 0
        this.refreshCards(width, height)
        this.refreshCategoryBtns(color)
      })
      btn.on('pointerover', () => btn.setColor('#' + color.toString(16).padStart(6, '0')))
      btn.on('pointerout', () => {
        if (this.activeCategory !== key) btn.setColor('#94a3b8')
      })

      this.categoryBtns.push(btn)
    })

    // Pagination
    this.prevBtn = this.add
      .text(width * 0.3, height * 0.93, '[ ← PREV ]', {
        fontFamily: 'monospace',
        fontSize: '13px',
        color: '#e2e8f0',
        backgroundColor: '#374151',
        padding: { x: 12, y: 6 },
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => {
        if (this.currentPage > 0) {
          this.currentPage--
          this.refreshCards(width, height)
        }
      })

    this.pageLabel = this.add
      .text(width / 2, height * 0.93, '', {
        fontFamily: 'monospace',
        fontSize: '12px',
        color: '#6b7280',
      })
      .setOrigin(0.5)

    this.nextBtn = this.add
      .text(width * 0.7, height * 0.93, '[ NEXT → ]', {
        fontFamily: 'monospace',
        fontSize: '13px',
        color: '#e2e8f0',
        backgroundColor: '#374151',
        padding: { x: 12, y: 6 },
      })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', () => {
        const games = this.getActiveGames()
        const totalPages = Math.ceil(games.length / CARDS_PER_PAGE)
        if (this.currentPage < totalPages - 1) {
          this.currentPage++
          this.refreshCards(width, height)
        }
      })

    this.refreshCategoryBtns(0xf59e0b)
    this.refreshCards(width, height)
  }

  private getActiveGames(): GameVariantConfig[] {
    if (this.activeCategory === 'hot') return getHotGames()
    return getGamesByCategory(this.activeCategory)
  }

  private refreshCategoryBtns(activeColor: number) {
    CATEGORIES.forEach(({ key, color }, i) => {
      const btn = this.categoryBtns[i]
      if (key === this.activeCategory) {
        btn.setColor('#' + activeColor.toString(16).padStart(6, '0'))
        btn.setAlpha(1)
      } else {
        btn.setColor('#' + color.toString(16).padStart(6, '0'))
        btn.setAlpha(0.5)
      }
    })
  }

  private refreshCards(width: number, height: number) {
    // Destroy old cards
    this.cardPool.forEach((c) => c.container.destroy())
    this.cardPool = []

    const games = this.getActiveGames()
    const totalPages = Math.ceil(games.length / CARDS_PER_PAGE)
    const pageGames = games.slice(this.currentPage * CARDS_PER_PAGE, (this.currentPage + 1) * CARDS_PER_PAGE)

    this.pageLabel.setText(`Page ${this.currentPage + 1} / ${totalPages}  (${games.length} games)`)
    this.prevBtn.setAlpha(this.currentPage > 0 ? 1 : 0.3)
    this.nextBtn.setAlpha(this.currentPage < totalPages - 1 ? 1 : 0.3)

    const cols = 3
    const rows = 2
    const cardW = width * 0.28
    const cardH = height * 0.24
    const startX = width * 0.18
    const startY = height * 0.35
    const gapX = width * 0.31
    const gapY = height * 0.28

    pageGames.forEach((game, idx) => {
      const col = idx % cols
      const row = Math.floor(idx / cols)
      const cx = startX + col * gapX
      const cy = startY + row * gapY

      const card = this.buildGameCard(game, cx, cy, cardW, cardH)
      this.cardPool.push({ container: card, game })
    })
  }

  private buildGameCard(game: GameVariantConfig, cx: number, cy: number, w: number, h: number): Phaser.GameObjects.Container {
    const container = this.add.container(cx, cy)

    const bg = this.add.rectangle(0, 0, w, h, 0x1a1a2e)
    bg.setStrokeStyle(1, game.primaryColor, 0.7)

    const hotBadge = game.hot
      ? this.add.text(w / 2 - 4, -h / 2 + 4, '🔥', { fontFamily: 'monospace', fontSize: '10px' }).setOrigin(1, 0)
      : null

    const categoryTag = this.add
      .text(-w / 2 + 8, -h / 2 + 8, game.category.toUpperCase(), {
        fontFamily: 'monospace',
        fontSize: '9px',
        color: '#' + game.primaryColor.toString(16).padStart(6, '0'),
      })
      .setOrigin(0, 0)

    const nameText = this.add
      .text(0, -h / 2 + 30, game.name, {
        fontFamily: 'monospace',
        fontSize: '12px',
        color: '#e2e8f0',
        align: 'center',
        wordWrap: { width: w - 16 },
      })
      .setOrigin(0.5, 0)

    const descText = this.add
      .text(0, 0, game.description, {
        fontFamily: 'monospace',
        fontSize: '9px',
        color: '#6b7280',
        align: 'center',
        wordWrap: { width: w - 16 },
      })
      .setOrigin(0.5, 0.5)

    const volColor = game.volatility === 'low' ? '#22c55e' : game.volatility === 'medium' ? '#f59e0b' : '#ef4444'
    const statsText = this.add
      .text(0, h / 2 - 34, `BET ${game.minBet}-${game.maxBet}  ·  ${game.volatility.toUpperCase()} VOL`, {
        fontFamily: 'monospace',
        fontSize: '9px',
        color: volColor,
      })
      .setOrigin(0.5, 1)

    const playBtn = this.add
      .text(0, h / 2 - 10, '[ PLAY ]', {
        fontFamily: 'monospace',
        fontSize: '11px',
        color: '#e2e8f0',
        backgroundColor: '#' + game.primaryColor.toString(16).padStart(6, '0'),
        padding: { x: 10, y: 4 },
      })
      .setOrigin(0.5, 1)

    const items: Phaser.GameObjects.GameObject[] = [bg, categoryTag, nameText, descText, statsText, playBtn]
    if (hotBadge) items.push(hotBadge)
    container.add(items)
    container.setSize(w, h)
    container.setInteractive({ useHandCursor: true })

    container.on('pointerover', () => bg.setStrokeStyle(2, game.primaryColor, 1))
    container.on('pointerout', () => bg.setStrokeStyle(1, game.primaryColor, 0.7))
    container.on('pointerdown', () => {
      this.scene.start(game.scene, { variant: game })
    })

    return container
  }
}

void ALL_GAMES
