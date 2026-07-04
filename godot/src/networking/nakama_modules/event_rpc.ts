// Live event read and faction war score submission
interface FactionScorePayload {
    faction?: string;
    score?: number;
}

const FACTION_WAR_KEY = "faction_war_scores";

const rpcGetActiveEvents: nkruntime.RpcFunction = function(
    _ctx: nkruntime.Context,
    _logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    _payload: string
): string {
    const EVENTS = [
        { id: "jackpot_hour", name: "Jackpot Hour 🎰", effect: "slot_mult_x2", duration_hours: 1 },
        { id: "double_xp", name: "Double XP", effect: "xp_x2", duration_hours: 48 },
        { id: "faction_war", name: "Faction War ⚔️", effect: "faction_score_boost", duration_hours: 24 },
        { id: "companion_safari", name: "Companion Safari 🐾", effect: "companion_unlock_boost", duration_hours: 12 },
        { id: "lucky_streak", name: "Lucky Streak 🍀", effect: "lck_boost_50", duration_hours: 2 },
        { id: "neon_race_cup", name: "Neon Race Cup 🏁", effect: "race_free_entry", duration_hours: 3 },
        { id: "void_surge", name: "Void Surge ⚫", effect: "void_stat_boost", duration_hours: 1.5 },
    ];

    const nowHour = Math.floor(Date.now() / 3600000);
    const activeEvent = EVENTS[nowHour % EVENTS.length];

    return JSON.stringify({ events: [activeEvent], server_time: new Date().toISOString() });
};

const rpcSubmitFactionScore: nkruntime.RpcFunction = function(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: FactionScorePayload;
    try { data = JSON.parse(payload); } catch { throw new Error("Invalid JSON"); }

    const { faction, score = 0 } = data;
    if (!faction) throw new Error("faction required");
    if (!["SovereignCrown", "WildlandsAscendant", "VeiledCurrent", "Factionless"].includes(faction))
        throw new Error("Invalid faction");

    let scores: Record<string, number> = { SovereignCrown: 0, WildlandsAscendant: 0, VeiledCurrent: 0, Factionless: 0 };
    try {
        const stored = nk.storageRead([{
            collection: "live_events",
            key: FACTION_WAR_KEY,
            userId: "00000000-0000-0000-0000-000000000000"
        }]);
        if (stored.length > 0) scores = stored[0].value as Record<string, number>;
    } catch { /* first score */ }

    scores[faction] = (scores[faction] ?? 0) + score;

    nk.storageWrite([{
        collection: "live_events",
        key: FACTION_WAR_KEY,
        userId: "00000000-0000-0000-0000-000000000000",
        value: scores,
        permissionRead: 2,
        permissionWrite: 0
    }]);

    logger.info("rpcSubmitFactionScore: %s submitted %d for %s", ctx.userId, score, faction);
    return JSON.stringify({ success: true, scores });
};

const rpcGetFactionScores: nkruntime.RpcFunction = function(
    _ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    _payload: string
): string {
    let scores: Record<string, number> = { SovereignCrown: 0, WildlandsAscendant: 0, VeiledCurrent: 0, Factionless: 0 };
    try {
        const stored = nk.storageRead([{
            collection: "live_events",
            key: FACTION_WAR_KEY,
            userId: "00000000-0000-0000-0000-000000000000"
        }]);
        if (stored.length > 0) scores = stored[0].value as Record<string, number>;
    } catch (e) {
        logger.warn("rpcGetFactionScores: %v", e);
    }
    return JSON.stringify({ scores });
};

export function register_event_rpc(
    _ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    _nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {
    initializer.registerRpc("get_active_events", rpcGetActiveEvents);
    initializer.registerRpc("submit_faction_score", rpcSubmitFactionScore);
    initializer.registerRpc("get_faction_scores", rpcGetFactionScores);
    logger.info("event_rpc module initialized");
}
