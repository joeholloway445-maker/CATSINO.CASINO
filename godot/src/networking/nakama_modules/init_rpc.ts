// Master init module — registers all RPCs and sets up initial state

export function register_init_rpc(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer): void {
  // Create leaderboards
  const leaderboards = ["global_wins", "global_coins", "slot_wins", "race_wins", "combat_wins", "puzzle_scores"];
  for (const id of leaderboards) {
    try {
      nk.leaderboardCreate(id, false, "desc", "best", "alltime", false);
      logger.info("Leaderboard created/confirmed: " + id);
    } catch (e) {
      logger.warn("Leaderboard already exists: " + id);
    }
  }

  logger.info("init_rpc: leaderboards ready (RPC modules register next)");
}
