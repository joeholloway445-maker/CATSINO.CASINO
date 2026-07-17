const LEADERBOARDS = [
  "weekly_coins", "all_time_wins", "tournament_champion", "racing_lap_times",
  "global_wins", "global_coins", "slot_wins", "race_wins", "combat_wins", "puzzle_scores",
];
const TOP_RECORD_LIMIT = 100;
const ADMIN_ROLE = "admin";

/** Clients send `board_id` (LeaderboardPanel / Leaderboard.gd) or `leaderboard`
 *  (arena submit). Accept either — Gate 8 field-alias. */
function resolveBoardId(data: {[key: string]: unknown}): string {
    const raw = data["leaderboard"] ?? data["board_id"] ?? "";
    return String(raw || "").trim();
}

// Submit a score to the appropriate leaderboard
function rpcSubmitScore(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: {[key: string]: unknown};
    try {
        data = JSON.parse(payload || "{}");
    } catch (e) {
        logger.error("rpcSubmitScore: invalid JSON payload: %s", payload);
        return JSON.stringify({ success: false, ok: false, error: "Invalid JSON payload" });
    }

    const leaderboard = resolveBoardId(data);
    const score = Number(data["score"]);
    const subscore = Number(data["subscore"] ?? 0);

    if (!leaderboard || !LEADERBOARDS.includes(leaderboard)) {
        return JSON.stringify({
            success: false, ok: false,
            error: `Unknown leaderboard: ${leaderboard || "(empty)"}. Valid: ${LEADERBOARDS.join(", ")}`
        });
    }

    if (!Number.isFinite(score) || score < 0) {
        return JSON.stringify({ success: false, ok: false, error: "Score must be a non-negative number" });
    }

    try {
        nk.leaderboardRecordWrite(
            leaderboard,
            ctx.userId,
            ctx.username,
            score,
            Number.isFinite(subscore) ? subscore : 0,
            {}
        );
    } catch (e) {
        logger.error("rpcSubmitScore: failed to write record for user %s: %v", ctx.userId, e);
        return JSON.stringify({ success: false, ok: false, error: "Failed to submit score" });
    }

    logger.info("rpcSubmitScore: user %s submitted score %d to %s", ctx.userId, score, leaderboard);

    return JSON.stringify({
        success: true, ok: true,
        leaderboard, board_id: leaderboard, score
    });
};

// Get top 100 records + caller's own rank
function rpcGetLeaderboard(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: {[key: string]: unknown};
    try {
        data = JSON.parse(payload || "{}");
    } catch (e) {
        return JSON.stringify({ success: false, ok: false, error: "Invalid JSON payload" });
    }

    const leaderboard = resolveBoardId(data);
    const limit = Math.min(TOP_RECORD_LIMIT, Math.max(1, Number(data["limit"] ?? TOP_RECORD_LIMIT) || TOP_RECORD_LIMIT));

    if (!leaderboard || !LEADERBOARDS.includes(leaderboard)) {
        return JSON.stringify({
            success: false, ok: false,
            error: `Unknown leaderboard: ${leaderboard || "(empty)"}`
        });
    }

    let topRecords: nkruntime.LeaderboardRecord[] = [];
    let callerRank = -1;
    let callerRecord: nkruntime.LeaderboardRecord | null = null;

    try {
        const result = nk.leaderboardRecordsList(
            leaderboard,
            [],
            limit,
            undefined,
            0
        );
        topRecords = result.records ?? [];
    } catch (e) {
        logger.error("rpcGetLeaderboard: failed to list records for %s: %v", leaderboard, e);
        return JSON.stringify({ success: false, ok: false, error: "Failed to retrieve leaderboard" });
    }

    // Find caller rank in top list
    for (let i = 0; i < topRecords.length; i++) {
        if (topRecords[i].ownerId === ctx.userId) {
            callerRank = i + 1;
            callerRecord = topRecords[i];
            break;
        }
    }

    // If not in top list, try to get their own record
    if (callerRank === -1) {
        try {
            const ownerResult = nk.leaderboardRecordsList(
                leaderboard,
                [ctx.userId],
                1,
                undefined,
                0
            );
            if (ownerResult.ownerRecords && ownerResult.ownerRecords.length > 0) {
                callerRecord = ownerResult.ownerRecords[0];
                callerRank = Number(callerRecord.rank);
            }
        } catch (e) {
            logger.warn("rpcGetLeaderboard: could not fetch caller record: %v", e);
        }
    }

    const serializedRecords = topRecords.map((r, idx) => ({
        rank: idx + 1,
        userId: r.ownerId,
        username: r.username,
        score: r.score,
        subscore: r.subscore,
        metadata: r.metadata ?? {}
    }));

    return JSON.stringify({
        success: true,
        ok: true,
        leaderboard,
        board_id: leaderboard,
        records: serializedRecords,
        caller_rank: callerRank,
        caller_record: callerRecord
            ? {
                  rank: callerRank,
                  userId: callerRecord.ownerId,
                  username: callerRecord.username,
                  score: callerRecord.score,
                  subscore: callerRecord.subscore
              }
            : null
    });
};

// Admin-only: reset weekly leaderboard and grant prizes to top 3
function rpcResetWeeklyLeaderboard(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    // Check admin role
    const userRoles: string[] = ctx.clientVars["roles"]
        ? (ctx.clientVars["roles"] as string).split(",")
        : [];

    const isAdmin = userRoles.includes(ADMIN_ROLE);
    if (!isAdmin) {
        logger.warn("rpcResetWeeklyLeaderboard: unauthorized attempt by user %s", ctx.userId);
        throw new Error("Unauthorized: admin role required");
    }

    const WEEKLY_LEADERBOARD = "weekly_coins";
    const PRIZES = [10000, 5000, 2500]; // 1st, 2nd, 3rd place coin prizes
    const WALLET_CHANGESET_CURRENCY = "coins";

    // Fetch top 3 before resetting
    let topRecords: nkruntime.LeaderboardRecord[] = [];
    try {
        const result = nk.leaderboardRecordsList(WEEKLY_LEADERBOARD, [], 3, undefined, 0);
        topRecords = result.records ?? [];
    } catch (e) {
        logger.error("rpcResetWeeklyLeaderboard: failed to list records: %v", e);
        throw new Error("Failed to retrieve top records");
    }

    // Grant prizes to top 3
    const prizesGranted: Array<{ userId: string; username: string; prize: number; rank: number }> = [];
    for (let i = 0; i < Math.min(3, topRecords.length); i++) {
        const record = topRecords[i];
        const prize = PRIZES[i];
        try {
            const changeset: { [key: string]: number } = {};
            changeset[WALLET_CHANGESET_CURRENCY] = prize;
            nk.walletUpdate(record.ownerId, changeset, {
                reason: `weekly_leaderboard_prize_rank_${i + 1}`,
                leaderboard: WEEKLY_LEADERBOARD
            });
            prizesGranted.push({
                userId: record.ownerId,
                username: record.username,
                prize,
                rank: i + 1
            });
            logger.info(
                "rpcResetWeeklyLeaderboard: granted %d coins to %s (rank %d)",
                prize,
                record.username,
                i + 1
            );
        } catch (e) {
            logger.error(
                "rpcResetWeeklyLeaderboard: failed to grant prize to %s: %v",
                record.ownerId,
                e
            );
        }
    }

    // Reset the weekly leaderboard by deleting all records
    // Nakama doesn't expose a bulk delete via TS runtime; delete top records individually
    for (const record of topRecords) {
        try {
            nk.leaderboardRecordDelete(WEEKLY_LEADERBOARD, record.ownerId);
        } catch (e) {
            logger.warn("rpcResetWeeklyLeaderboard: failed to delete record for %s: %v", record.ownerId, e);
        }
    }

    logger.info("rpcResetWeeklyLeaderboard: reset complete by admin %s", ctx.userId);

    return JSON.stringify({
        success: true,
        prizes_granted: prizesGranted,
        reset_leaderboard: WEEKLY_LEADERBOARD
    });
};

// Register RPCs
export function register_leaderboard_rpc(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {
    initializer.registerRpc("submit_score", rpcSubmitScore);
    initializer.registerRpc("get_leaderboard", rpcGetLeaderboard);
    initializer.registerRpc("reset_weekly_leaderboard", rpcResetWeeklyLeaderboard);
    logger.info("leaderboard_rpc module initialized");
}
