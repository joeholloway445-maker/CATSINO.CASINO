import { spendCoins, payCoins, ok } from "./wallet_util";

const SYMBOLS = ["🐱", "🌟", "🎭", "🐾", "💎", "🎰"];
const SYMBOL_WEIGHTS = [30, 20, 18, 15, 10, 7];
const TOTAL_WEIGHT = SYMBOL_WEIGHTS.reduce((a, b) => a + b, 0);

const PAYOUT_TABLE: Record<string, number> = {
  "🐱": 2, "🌟": 3, "🎭": 3, "🐾": 5, "💎": 10, "🎰": 20,
};

function weightedPick(nk: nkruntime.Nakama): string {
  const roll = nk.mathRandom() * TOTAL_WEIGHT;
  let acc = 0;
  for (let i = 0; i < SYMBOL_WEIGHTS.length; i++) {
    acc += SYMBOL_WEIGHTS[i];
    if (roll < acc) return SYMBOLS[i];
  }
  return SYMBOLS[0];
}

export function rpcBuyScratchCard(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string
): string {
  let data: { bet?: number };
  try { data = JSON.parse(payload); } catch { throw new Error("Invalid JSON"); }

  const bet = data.bet ?? 50;
  if (bet <= 0) throw new Error("Invalid bet");

  spendCoins(nk, ctx.userId, bet, "scratch_card_buy");

  const cells: string[] = [];
  const guarantee_win = nk.mathRandom() < 0.35;

  if (guarantee_win) {
    const winning_sym = weightedPick(nk);
    const positions = [0, 1, 2, 3, 4, 5, 6, 7, 8];
    for (let i = positions.length - 1; i > 0; i--) {
      const j = Math.floor(nk.mathRandom() * (i + 1));
      [positions[i], positions[j]] = [positions[j], positions[i]];
    }
    const win_positions = new Set(positions.slice(0, 3));
    for (let i = 0; i < 9; i++) {
      cells.push(win_positions.has(i) ? winning_sym : weightedPick(nk));
    }
  } else {
    for (let attempt = 0; attempt < 10; attempt++) {
      cells.length = 0;
      for (let i = 0; i < 9; i++) cells.push(weightedPick(nk));
      const counts: Record<string, number> = {};
      for (const s of cells) counts[s] = (counts[s] ?? 0) + 1;
      if (!Object.values(counts).some(c => c >= 3)) break;
    }
  }

  const counts: Record<string, number> = {};
  for (const s of cells) counts[s] = (counts[s] ?? 0) + 1;
  let payout = 0;
  for (const sym in counts) {
    if (counts[sym] >= 3) {
      payout = Math.floor(bet * (PAYOUT_TABLE[sym] ?? 1));
      break;
    }
  }
  payCoins(nk, ctx.userId, payout, "scratch_card_win");

  logger.info("rpcBuyScratchCard: %s bet=%d payout=%d", ctx.userId, bet, payout);
  return ok({ cells, payout, is_win: payout > 0, bet });
};

export function register_scratch_rpc(
  _ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  _nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer
): void {
  logger.info("scratch_rpc module initialized");
}
