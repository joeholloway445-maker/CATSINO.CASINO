// Nakama TypeScript server-side leaderboard module
// Deploy to: nakama/data/modules/leaderboard_rpc.ts

const collections = {
  weekly_coins:        "weekly_coins",
  all_time_wins:       "all_time_wins",
  tournament_champion: "tournament_champion",
  racing_lap_times:    "racing_lap_times",
}

// ── Submit score ──────────────────────────────────────────────────────────────
const rpcSubmitScore: nkruntime.RpcFunction = (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string,
): string => {
  const data = JSON.parse(payload || "{}") as { leaderboard: string; score: number; subscore?: number }
  const lb = data.leaderboard
  if (!collections[lb as keyof typeof collections]) {
    throw Error(`Unknown leaderboard: ${lb}`)
  }
  const score = Math.floor(data.score)
  if (isNaN(score) || score < 0) throw Error("Invalid score")

  nk.leaderboardRecordWrite(lb, ctx.userId, ctx.username, score, data.subscore ?? 0)
  logger.info("Score submitted: %s → %s=%d", ctx.userId, lb, score)
  return JSON.stringify({ ok: true, leaderboard: lb, score })
}

// ── Get leaderboard ───────────────────────────────────────────────────────────
const rpcGetLeaderboard: nkruntime.RpcFunction = (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string,
): string => {
  const data = JSON.parse(payload || "{}") as { leaderboard: string; limit?: number }
  const lb = data.leaderboard || "all_time_wins"
  if (!collections[lb as keyof typeof collections]) {
    throw Error(`Unknown leaderboard: ${lb}`)
  }
  const limit = Math.min(data.limit ?? 100, 100)

  const result = nk.leaderboardRecordsList(lb, [], limit, undefined, 1)
  // Get caller's own rank
  let myRank: nkruntime.LeaderboardRecord | null = null
  try {
    const mine = nk.leaderboardRecordsList(lb, [ctx.userId], 1, undefined, 1)
    myRank = mine.records?.[0] ?? null
  } catch (_) {}

  return JSON.stringify({
    ok: true,
    leaderboard: lb,
    records: result.records ?? [],
    my_rank: myRank,
    next_cursor: result.nextCursor ?? null,
  })
}

// ── Reset weekly leaderboard (admin only) ─────────────────────────────────────
const rpcResetWeeklyLeaderboard: nkruntime.RpcFunction = (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  _payload: string,
): string => {
  // Only server-to-server calls or admins
  if (ctx.userId !== "" && !ctx.clientIp.startsWith("127.")) {
    throw Error("Admin only")
  }

  // Pay out top 3
  const result = nk.leaderboardRecordsList("weekly_coins", [], 3, undefined, 1)
  const prizes = [10000, 5000, 2500]
  const records = result.records ?? []
  for (let i = 0; i < Math.min(records.length, 3); i++) {
    const r = records[i]
    nk.walletUpdate(r.ownerId, { cat_coins: prizes[i] }, { source: "weekly_leaderboard_prize", rank: i + 1 })
    logger.info("Weekly prize: rank %d → %s (+%d coins)", i + 1, r.ownerId, prizes[i])
  }

  nk.leaderboardDelete("weekly_coins")
  nk.leaderboardCreate("weekly_coins", true, "desc", "set", "0 0 * * 1", false)
  logger.info("Weekly leaderboard reset by %s", ctx.userId || "system")

  return JSON.stringify({ ok: true, prizes_paid: Math.min(records.length, 3) })
}

// ── Register ──────────────────────────────────────────────────────────────────
function InitModule(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer,
): void {
  // Ensure leaderboards exist
  const lbDefs: Array<[string, string]> = [
    ["weekly_coins",        "0 0 * * 1"],   // reset Mondays
    ["all_time_wins",       ""],
    ["tournament_champion", ""],
    ["racing_lap_times",    ""],
  ]
  for (const [id, resetSchedule] of lbDefs) {
    try {
      nk.leaderboardCreate(id, true, "desc", "best", resetSchedule, false)
    } catch (_) {} // already exists
  }

  initializer.registerRpc("submit_score",            rpcSubmitScore)
  initializer.registerRpc("get_leaderboard",         rpcGetLeaderboard)
  initializer.registerRpc("reset_weekly_leaderboard",rpcResetWeeklyLeaderboard)
  logger.info("leaderboard_rpc module loaded")
}

// @ts-ignore
!InitModule && InitModule
