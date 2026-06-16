const BOARD_IDS = ["global_wins", "global_coins", "slot_wins", "race_wins", "combat_wins", "puzzle_scores"];

const ScoreRpc = {
  submitScore: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");

    const { board_id, score, subscore = 0 } = JSON.parse(payload || "{}");
    if (!BOARD_IDS.includes(board_id)) throw new Error("Unknown leaderboard: " + board_id);
    if (typeof score !== "number" || score < 0) throw new Error("Invalid score");

    nk.leaderboardRecordWrite(board_id, userId, ctx.username || "player", score, subscore, {});
    return JSON.stringify({ success: true, board_id, score });
  },

  getLeaderboard: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const { board_id = "global_wins", limit = 20 } = JSON.parse(payload || "{}");
    if (!BOARD_IDS.includes(board_id)) throw new Error("Unknown leaderboard");

    const result = nk.leaderboardRecordsList(board_id, [], Math.min(limit, 100), undefined, 0);
    const records = (result.records || []).map((r: any) => ({
      rank: r.rank,
      username: r.username,
      score: r.score,
      subscore: r.subscore,
    }));
    return JSON.stringify({ records });
  }
};

function InitModule(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer): void {
  // Ensure leaderboards exist
  for (const id of BOARD_IDS) {
    try {
      nk.leaderboardCreate(id, false, "desc", "best", "alltime", false);
    } catch (_) { /* already exists */ }
  }
  initializer.registerRpc("submit_score", ScoreRpc.submitScore);
  initializer.registerRpc("get_leaderboard", ScoreRpc.getLeaderboard);
  logger.info("Score/Leaderboard RPC module loaded");
}
