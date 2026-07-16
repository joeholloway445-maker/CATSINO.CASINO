import { spendCoins, payCoins, ok } from "./wallet_util";

/** Matches OfflineCasino tier multipliers on bet. */
function payoutFor(score: number, bet: number): { payout: number; multiplier: number; tier: string } {
  let mult = 0;
  let tier = "No reward";
  if (score >= 500) { mult = 2.0; tier = "Score 500+"; }
  else if (score >= 300) { mult = 1.5; tier = "Score 300+"; }
  else if (score >= 150) { mult = 1.0; tier = "Score 150+"; }
  else if (score >= 50) { mult = 0.5; tier = "Score 50+"; }
  return { payout: Math.floor(bet * mult), multiplier: mult, tier };
}

const PuzzleRpc = {
  submitPuzzleScore: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");

    const { score, bet } = JSON.parse(payload || "{}");
    if (typeof score !== "number" || score < 0 || score > 1000) throw new Error("Invalid score");
    if (!bet || bet < 10 || bet > 5000) throw new Error("Invalid bet");

    spendCoins(nk, userId, bet, "puzzle_entry");
    const { payout, multiplier, tier } = payoutFor(score, bet);
    payCoins(nk, userId, payout, "puzzle_win");

    try {
      nk.leaderboardRecordWrite("puzzle_scores", userId, ctx.username || "player", score, 0, {});
    } catch (_e) {
      // leaderboard may not exist yet
    }

    return ok({ score, payout, multiplier, tier, achieved_500: score >= 500 });
  }
};

export function register_puzzle_rpc(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer): void {
  initializer.registerRpc("submit_puzzle_score", PuzzleRpc.submitPuzzleScore);
  logger.info("Puzzle RPC module loaded");
}
