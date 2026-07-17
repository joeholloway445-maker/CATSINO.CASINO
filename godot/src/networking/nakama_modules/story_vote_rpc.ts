// StoryVote — Arena development referendum (Gate 8 local multiplayer).
// Soft cap: one vote per ballot per SERVER DAY (4 hours). Tallies stack
// globally; personal vote history lives on the user object.

const SERVER_DAY_MS = 4 * 3600 * 1000;
const SYSTEM_USER = "00000000-0000-0000-0000-000000000000";
const COLLECTION_MINE = "story_votes";
const COLLECTION_TALLY = "story_tallies";

interface StoryVotePayload {
    ballot?: string;
    option?: number;
}

interface VoteRecord {
    option: number;
    voted_at: number; // unix ms
}

interface TallyRecord {
    counts: Record<string, number>;
    total: number;
    updated_at: number;
}

function _readMine(
    nk: nkruntime.Nakama,
    userId: string,
    ballot: string
): VoteRecord | null {
    try {
        const stored = nk.storageRead([{
            collection: COLLECTION_MINE,
            key: ballot,
            userId
        }]);
        if (stored.length > 0 && stored[0].value) {
            return stored[0].value as unknown as VoteRecord;
        }
    } catch (_e) { /* first vote */ }
    return null;
}

function _readTally(nk: nkruntime.Nakama, ballot: string): TallyRecord {
    try {
        const stored = nk.storageRead([{
            collection: COLLECTION_TALLY,
            key: ballot,
            userId: SYSTEM_USER
        }]);
        if (stored.length > 0 && stored[0].value) {
            return stored[0].value as unknown as TallyRecord;
        }
    } catch (_e) { /* first tally */ }
    return { counts: {}, total: 0, updated_at: 0 };
}

const rpcStoryVote: nkruntime.RpcFunction = function (
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    if (!ctx.userId) {
        return JSON.stringify({ success: false, ok: false, error: "Not authenticated" });
    }

    let data: StoryVotePayload;
    try {
        data = JSON.parse(payload || "{}");
    } catch (_e) {
        return JSON.stringify({ success: false, ok: false, error: "Invalid JSON payload" });
    }

    const ballot = String(data.ballot || "").trim();
    const option = Number(data.option);
    if (!ballot) {
        return JSON.stringify({ success: false, ok: false, error: "ballot required" });
    }
    if (!Number.isFinite(option) || option < 0 || Math.floor(option) !== option) {
        return JSON.stringify({ success: false, ok: false, error: "option must be a non-negative integer" });
    }

    const now = Date.now();
    const prior = _readMine(nk, ctx.userId, ballot);
    if (prior && (now - Number(prior.voted_at || 0)) < SERVER_DAY_MS) {
        const retry_in = Math.max(0, Math.ceil((SERVER_DAY_MS - (now - Number(prior.voted_at || 0))) / 1000));
        return JSON.stringify({
            success: false,
            ok: false,
            reason: "cooldown",
            retry_in,
            message: "One vote per ballot per server day (4h)."
        });
    }

    const record: VoteRecord = { option, voted_at: now };
    try {
        nk.storageWrite([{
            collection: COLLECTION_MINE,
            key: ballot,
            userId: ctx.userId,
            value: record as unknown as {[key: string]: unknown},
            permissionRead: 1,
            permissionWrite: 0
        }]);
    } catch (e) {
        logger.error("rpcStoryVote: failed to write vote for %s: %v", ctx.userId, e);
        return JSON.stringify({ success: false, ok: false, error: "Failed to record vote" });
    }

    const tally = _readTally(nk, ballot);
    const key = String(option);
    tally.counts[key] = (tally.counts[key] ?? 0) + 1;
    tally.total = (tally.total ?? 0) + 1;
    tally.updated_at = now;
    try {
        nk.storageWrite([{
            collection: COLLECTION_TALLY,
            key: ballot,
            userId: SYSTEM_USER,
            value: tally as unknown as {[key: string]: unknown},
            permissionRead: 2,
            permissionWrite: 0
        }]);
    } catch (e) {
        logger.warn("rpcStoryVote: tally write soft-fail for %s: %v", ballot, e);
    }

    logger.info("rpcStoryVote: %s voted ballot=%s option=%d (total=%d)",
        ctx.userId, ballot, option, tally.total);
    return JSON.stringify({
        success: true,
        ok: true,
        recorded: true,
        ballot,
        option,
        tallies: tally.counts,
        total: tally.total
    });
};

const rpcGetStoryTallies: nkruntime.RpcFunction = function (
    _ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let ballot = "";
    try {
        const data = JSON.parse(payload || "{}") as StoryVotePayload;
        ballot = String(data.ballot || "").trim();
    } catch (_e) { /* optional */ }

    if (ballot) {
        const tally = _readTally(nk, ballot);
        return JSON.stringify({
            success: true,
            ok: true,
            ballot,
            tallies: tally.counts,
            total: tally.total
        });
    }

    // List all tallies (bounded).
    const out: Record<string, TallyRecord> = {};
    try {
        let cursor: string | undefined = undefined;
        do {
            const page = nk.storageList(SYSTEM_USER, COLLECTION_TALLY, 50, cursor);
            for (const obj of page.objects ?? []) {
                out[obj.key] = obj.value as unknown as TallyRecord;
            }
            cursor = page.cursor;
        } while (cursor);
    } catch (e) {
        logger.warn("rpcGetStoryTallies: list soft-fail: %v", e);
    }
    return JSON.stringify({ success: true, ok: true, ballots: out });
};

export function register_story_vote_rpc(
    _ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    _nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {
    initializer.registerRpc("story_vote", rpcStoryVote);
    initializer.registerRpc("get_story_tallies", rpcGetStoryTallies);
    logger.info("story_vote_rpc module initialized");
}
