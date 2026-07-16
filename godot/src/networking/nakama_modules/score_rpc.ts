/** Creates extended leaderboard boards. submit_score / get_leaderboard
 *  are owned by leaderboard_rpc — do not re-register them here. */

const BOARD_IDS = ["global_wins", "global_coins", "slot_wins", "race_wins", "combat_wins", "puzzle_scores"];

export function register_score_rpc(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer): void {
  for (const id of BOARD_IDS) {
    try {
      nk.leaderboardCreate(id, false, "desc", "best", "alltime", false);
    } catch (_) { /* already exists */ }
  }
  logger.info("Score boards ensured (RPCs owned by leaderboard_rpc)");
}
