import { spendCoins, payCoins, ok } from "./wallet_util";

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
  if (v === 0) return 11;
  if (v >= 10) return 10;
  return v + 1;
}

function handValue(cards: number[]): number {
  let total = 0;
  let aces = 0;
  for (const c of cards) {
    const v = cardValue(c);
    if (v === 11) aces++;
    total += v;
  }
  while (total > 21 && aces > 0) {
    total -= 10;
    aces--;
  }
  return total;
}

function playBlackjack(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");

    const { action, bet } = JSON.parse(payload || "{}");
    if (action === "deal" && (!bet || bet < 10 || bet > 100000)) throw new Error("Invalid bet");

    if (action === "deal") {
      spendCoins(nk, userId, bet, "blackjack_deal");
      const deck = shuffleDeck();
      const playerCards = [deck[0], deck[2]];
      const dealerCards = [deck[1], deck[3]];
      const playerValue = handValue(playerCards);

      nk.storageWrite([{
        collection: "bj_session",
        key: "hand",
        userId,
        value: JSON.stringify({ deck, playerCards, dealerCards, deckIdx: 4, bet }),
        permissionRead: 1,
        permissionWrite: 1
      }]);

      if (playerValue === 21) {
        const payout = Math.floor(bet * 2.5);
        payCoins(nk, userId, payout, "blackjack_win");
        nk.storageDelete([{ collection: "bj_session", key: "hand", userId }]);
        return ok({
          player_cards: playerCards,
          dealer_cards: [dealerCards[0], -1],
          player_value: 21,
          dealer_value: cardValue(dealerCards[0]),
          outcome: "blackjack",
          payout,
        });
      }

      return ok({
        player_cards: playerCards,
        dealer_cards: [dealerCards[0], -1],
        player_value: playerValue,
        dealer_value: cardValue(dealerCards[0]),
      });
    }

    const sessions = nk.storageRead([{ collection: "bj_session", key: "hand", userId }]);
    if (!sessions || sessions.length === 0) throw new Error("No active hand");
    const session = JSON.parse(sessions[0].value as string);
    let { deck, playerCards, dealerCards, deckIdx, bet: sessionBet } = session;

    if (action === "hit") {
      playerCards.push(deck[deckIdx++]);
      const pv = handValue(playerCards);
      if (pv > 21) {
        nk.storageDelete([{ collection: "bj_session", key: "hand", userId }]);
        return ok({
          player_cards: playerCards,
          dealer_cards: dealerCards,
          player_value: pv,
          dealer_value: handValue(dealerCards),
          outcome: "bust",
          payout: 0,
        });
      }
      nk.storageWrite([{
        collection: "bj_session", key: "hand", userId,
        value: JSON.stringify({ deck, playerCards, dealerCards, deckIdx, bet: sessionBet }),
        permissionRead: 1, permissionWrite: 1,
      }]);
      return ok({
        player_cards: playerCards,
        dealer_cards: [dealerCards[0], -1],
        player_value: pv,
        dealer_value: cardValue(dealerCards[0]),
      });
    }

    if (action === "stand" || action === "double") {
      if (action === "double") {
        spendCoins(nk, userId, sessionBet, "blackjack_double");
        sessionBet *= 2;
        playerCards.push(deck[deckIdx++]);
      }
      while (handValue(dealerCards) < 17) dealerCards.push(deck[deckIdx++]);
      const pv = handValue(playerCards);
      const dv = handValue(dealerCards);
      let outcome = "lose";
      let payout = 0;
      if (pv > 21) outcome = "bust";
      else if (dv > 21) { outcome = "dealer_bust"; payout = sessionBet * 2; }
      else if (pv > dv) { outcome = "win"; payout = sessionBet * 2; }
      else if (pv === dv) { outcome = "push"; payout = sessionBet; }
      payCoins(nk, userId, payout, `blackjack_${outcome}`);
      nk.storageDelete([{ collection: "bj_session", key: "hand", userId }]);
      return ok({
        player_cards: playerCards,
        dealer_cards: dealerCards,
        player_value: pv,
        dealer_value: dv,
        outcome,
        payout,
      });
    }

    throw new Error("Unknown action");
  }


export function register_blackjack_rpc(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer): void {
  initializer.registerRpc("play_blackjack", playBlackjack);
  logger.info("Blackjack RPC module loaded");
}
