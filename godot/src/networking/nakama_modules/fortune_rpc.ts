import { spendCoins, payCoins, ok } from "./wallet_util";

/** Matches OfflineCasino + FortuneWheel client (12 segments, bet multipliers). */
const SEGMENTS = [
  { name: "Void", mult: 0.0 },
  { name: "Coin", mult: 1.0 },
  { name: "Coin", mult: 1.0 },
  { name: "Bronze", mult: 1.5 },
  { name: "Void", mult: 0.0 },
  { name: "Bronze", mult: 1.5 },
  { name: "Silver", mult: 2.0 },
  { name: "Void", mult: 0.0 },
  { name: "Silver", mult: 2.0 },
  { name: "Gold", mult: 3.0 },
  { name: "Diamond", mult: 5.0 },
  { name: "Royal", mult: 10.0 },
];

const FortuneRpc = {
  drawFortune: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");

    const { bet } = JSON.parse(payload || "{}");
    if (!bet || bet < 20 || bet > 10000) throw new Error("Invalid bet");

    spendCoins(nk, userId, bet, "fortune_spin");
    const segmentIndex = Math.floor(Math.random() * SEGMENTS.length);
    const segment = SEGMENTS[segmentIndex];
    const payout = Math.floor(bet * segment.mult);
    payCoins(nk, userId, payout, "fortune_win");

    return ok({
      segment: segmentIndex,
      segment_index: segmentIndex,
      segment_name: segment.name,
      multiplier: segment.mult,
      payout,
      bet,
    });
  }
};

export function register_fortune_rpc(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer): void {
  initializer.registerRpc("draw_fortune", FortuneRpc.drawFortune);
  logger.info("Fortune wheel RPC module loaded");
}
