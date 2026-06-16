const HAND_RANKS = ["High Card", "One Pair", "Two Pair", "Three of a Kind", "Straight", "Flush", "Full House", "Four of a Kind", "Straight Flush", "Royal Flush"];

const PAYOUTS: Record<string, number> = {
  "High Card": 0,
  "One Pair": 1,
  "Two Pair": 2,
  "Three of a Kind": 3,
  "Straight": 4,
  "Flush": 6,
  "Full House": 9,
  "Four of a Kind": 25,
  "Straight Flush": 50,
  "Royal Flush": 250,
};

function shuffleDeck(): number[] {
  const deck = Array.from({ length: 52 }, (_, i) => i);
  for (let i = deck.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [deck[i], deck[j]] = [deck[j], deck[i]];
  }
  return deck;
}

function cardValue(card: number): number { return card % 13; }
function cardSuit(card: number): number { return Math.floor(card / 13); }

function evaluateHand(cards: number[]): string {
  const values = cards.map(cardValue).sort((a, b) => a - b);
  const suits = cards.map(cardSuit);
  const valueCounts: Record<number, number> = {};
  for (const v of values) valueCounts[v] = (valueCounts[v] || 0) + 1;
  const counts = Object.values(valueCounts).sort((a, b) => b - a);
  const isFlush = suits.every(s => s === suits[0]);
  const isStraight = values[4] - values[0] === 4 && new Set(values).size === 5;
  const isRoyalStraight = JSON.stringify(values) === JSON.stringify([0, 9, 10, 11, 12]);

  if (isFlush && isRoyalStraight) return "Royal Flush";
  if (isFlush && isStraight) return "Straight Flush";
  if (counts[0] === 4) return "Four of a Kind";
  if (counts[0] === 3 && counts[1] === 2) return "Full House";
  if (isFlush) return "Flush";
  if (isStraight) return "Straight";
  if (counts[0] === 3) return "Three of a Kind";
  if (counts[0] === 2 && counts[1] === 2) return "Two Pair";
  if (counts[0] === 2) return "One Pair";
  return "High Card";
}

const PokerRpc = {
  playPoker: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");

    const { action, bet, held } = JSON.parse(payload || "{}");
    if (!bet || bet < 10 || bet > 50000) throw new Error("Invalid bet");

    if (action === "deal") {
      nk.walletsUpdate([{ userId, changeset: { cat_coins: -bet }, metadata: { reason: "poker_deal" } }], true);
      const deck = shuffleDeck();
      const cards = deck.slice(0, 5);
      nk.storageWrite([{
        collection: "poker_session",
        key: "hand",
        userId,
        value: JSON.stringify({ deck, cards, bet }),
        permissionRead: 1,
        permissionWrite: 1
      }]);
      return JSON.stringify({ cards });
    }

    if (action === "draw") {
      const sessions = nk.storageRead([{ collection: "poker_session", key: "hand", userId }]);
      if (!sessions || sessions.length === 0) throw new Error("No active hand");
      const session = JSON.parse(sessions[0].value);
      const heldArr: boolean[] = held || [false, false, false, false, false];
      const deck: number[] = session.deck;
      let deckIdx = 5;
      const newCards = session.cards.map((card: number, i: number) => {
        if (heldArr[i]) return card;
        return deck[deckIdx++];
      });
      const handName = evaluateHand(newCards);
      const multiplier = PAYOUTS[handName] || 0;
      const payout = session.bet * multiplier;
      if (payout > 0) {
        nk.walletsUpdate([{ userId, changeset: { cat_coins: payout }, metadata: { reason: "poker_win", hand: handName } }], true);
      }
      nk.storageDelete([{ collection: "poker_session", key: "hand", userId }]);
      return JSON.stringify({ cards: newCards, hand_name: handName, payout, multiplier });
    }

    throw new Error("Unknown action");
  }
};

function InitModule(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer): void {
  initializer.registerRpc("play_poker", PokerRpc.playPoker);
  logger.info("Poker RPC module loaded");
}
