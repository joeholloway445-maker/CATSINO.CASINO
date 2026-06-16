const SCORE_TIERS = [
  { min: 50, payout: 100 },
  { min: 150, payout: 300 },
  { min: 300, payout: 750 },
  { min: 500, payout: 2000 },
];

const PuzzleRpc = {
  submitPuzzleScore: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");

    const { score, bet } = JSON.parse(payload || "{}");
    if (typeof score !== "number" || score < 0 || score > 1000) throw new Error("Invalid score");
    if (!bet || bet < 10 || bet > 5000) throw new Error("Invalid bet");

    let payout = 0;
    let tier = "";
    for (const t of SCORE_TIERS) {
      if (score >= t.min) {
        payout = t.payout;
        tier = `Score ${t.min}+`;
      }
    }

    if (payout > 0) {
      nk.walletsUpdate([{ userId, changeset: { cat_coins: payout }, metadata: { reason: "puzzle_win", score, tier } }], true);
    }

    nk.leaderboardRecordWrite("puzzle_scores", userId, ctx.username || "player", score, 0, {});

    return JSON.stringify({ score, payout, tier: tier || "No reward", achieved_500: score >= 500 });
  }
};

function InitModule(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer): void {
  initializer.registerRpc("submit_puzzle_score", PuzzleRpc.submitPuzzleScore);
  logger.info("Puzzle RPC module loaded");
}
