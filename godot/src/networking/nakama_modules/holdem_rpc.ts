function shuffleDeck(): number[] {
  const deck = Array.from({ length: 52 }, (_, i) => i);
  for (let i = deck.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [deck[i], deck[j]] = [deck[j], deck[i]];
  }
  return deck;
}

function cardValue(index: number): number {
  const v = index % 13;
  if (v === 0) return 14;
  return v + 1;
}

function evaluateBestHand(cards: number[]): { name: string; score: number } {
  const values = cards.map(c => cardValue(c)).sort((a, b) => b - a);
  const suits = cards.map(c => Math.floor(c / 13));
  const valueCounts: Record<number, number> = {};
  for (const v of values) valueCounts[v] = (valueCounts[v] || 0) + 1;
  const counts = Object.values(valueCounts).sort((a, b) => b - a);
  const isFlush = suits.length >= 5 && suits.slice(0, 5).every(s => s === suits[0]);
  const uniqueVals = [...new Set(values)].sort((a, b) => b - a);
  const isStraight = uniqueVals.length >= 5 && uniqueVals[0] - uniqueVals[4] === 4;

  if (isFlush && isStraight && values[0] === 14) return { name: "Royal Flush", score: 900 };
  if (isFlush && isStraight) return { name: "Straight Flush", score: 800 };
  if (counts[0] === 4) return { name: "Four of a Kind", score: 700 };
  if (counts[0] === 3 && counts[1] === 2) return { name: "Full House", score: 600 };
  if (isFlush) return { name: "Flush", score: 500 };
  if (isStraight) return { name: "Straight", score: 400 };
  if (counts[0] === 3) return { name: "Three of a Kind", score: 300 };
  if (counts[0] === 2 && counts[1] === 2) return { name: "Two Pair", score: 200 };
  if (counts[0] === 2) return { name: "One Pair", score: 100 };
  return { name: "High Card", score: values[0] };
}

const HAND_PAYOUTS: Record<string, number> = {
  "High Card": 0, "One Pair": 1, "Two Pair": 2, "Three of a Kind": 3,
  "Straight": 4, "Flush": 6, "Full House": 9, "Four of a Kind": 25,
  "Straight Flush": 50, "Royal Flush": 250
};

const HoldemRpc = {
  playHoldem: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");

    const { action, bet } = JSON.parse(payload || "{}");
    if (!bet || bet < 10 || bet > 50000) throw new Error("Invalid bet");

    if (action === "deal") {
      nk.walletsUpdate([{ userId, changeset: { cat_coins: -bet }, metadata: { reason: "holdem_deal" } }], true);
      const deck = shuffleDeck();
      const holeCards = [deck[0], deck[1]];
      const communityCards = [deck[2], deck[3], deck[4], -1, -1]; // flop only, turn/river hidden
      nk.storageWrite([{
        collection: "holdem_session", key: "hand", userId,
        value: JSON.stringify({ deck, holeCards, community: [deck[2], deck[3], deck[4], deck[5], deck[6]], bet, phase: "flop" }),
        permissionRead: 1, permissionWrite: 1
      }]);
      return JSON.stringify({ hole_cards: holeCards, community_cards: communityCards });
    }

    const sessions = nk.storageRead([{ collection: "holdem_session", key: "hand", userId }]);
    if (!sessions || sessions.length === 0) throw new Error("No active hand");
    const session = JSON.parse(sessions[0].value);

    if (action === "fold") {
      nk.storageDelete([{ collection: "holdem_session", key: "hand", userId }]);
      return JSON.stringify({ outcome: "fold", payout: 0, community_cards: session.community.slice(0, 3).concat([-1, -1]) });
    }

    if (action === "call") {
      const allCards = session.holeCards.concat(session.community);
      const playerHand = evaluateBestHand(allCards);
      const payout = bet * (HAND_PAYOUTS[playerHand.name] || 0);
      if (payout > 0) {
        nk.walletsUpdate([{ userId, changeset: { cat_coins: payout }, metadata: { reason: "holdem_win", hand: playerHand.name } }], true);
      }
      nk.storageDelete([{ collection: "holdem_session", key: "hand", userId }]);
      return JSON.stringify({ outcome: payout > 0 ? "win" : "lose", hand_name: playerHand.name, payout, community_cards: session.community });
    }

    throw new Error("Unknown action");
  }
};

export function register_holdem_rpc(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer): void {
  initializer.registerRpc("play_holdem", HoldemRpc.playHoldem);
  logger.info("Holdem RPC module loaded");
}
