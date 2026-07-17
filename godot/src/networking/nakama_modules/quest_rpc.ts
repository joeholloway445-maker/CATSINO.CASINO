// Server-side quest progress sync and reward distribution
interface QuestProgress {
    quest_id: string;
    objective_id?: string;
    value?: number;
    action?: "accept" | "complete";
}

interface StoredQuest {
    quest_id: string;
    state: string;
    progress: Record<string, number>;
    accepted_at: string;
    completed_at?: string;
}

const QUEST_REWARDS: Record<string, { coins: number; xp: number; gems?: number }> = {
    "intro_district_tour":  { coins: 500,  xp: 100 },
    "first_battle":         { coins: 300,  xp: 75 },
    "find_sovereign_crown": { coins: 1000, xp: 200, gems: 5 },
    "faction_allegiance":   { coins: 800,  xp: 150 },
    "help_aqua_merchant":   { coins: 400,  xp: 80 },
    "neon_alley_racer":     { coins: 600,  xp: 120 },
    "forest_mystery":       { coins: 700,  xp: 140 },
    "arcade_champion":      { coins: 500,  xp: 100 },
    "daily_spin_3":         { coins: 200,  xp: 50 },
    "daily_win_race":       { coins: 300,  xp: 60 },
    "daily_companion_bond": { coins: 150,  xp: 40 },
    "faction_dominance":    { coins: 2000, xp: 400, gems: 10 },
    "companion_collector":  { coins: 1500, xp: 300, gems: 5 },
    "grand_tournament":     { coins: 5000, xp: 1000, gems: 25 },
    "sovereign_trial":      { coins: 3000, xp: 600, gems: 15 },
};

export function rpcQuestAction(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: QuestProgress;
    try { data = JSON.parse(payload); } catch { throw new Error("Invalid JSON"); }

    const { quest_id, action = "accept", objective_id, value = 1 } = data;
    if (!quest_id) throw new Error("quest_id required");

    let quests: Record<string, StoredQuest> = {};
    try {
        const stored = nk.storageRead([{ collection: "player_data", key: "quests", userId: ctx.userId }]);
        if (stored.length > 0) quests = stored[0].value as Record<string, StoredQuest>;
    } catch { /* empty */ }

    if (action === "accept") {
        if (quests[quest_id]?.state === "active" || quests[quest_id]?.state === "completed")
            return JSON.stringify({ success: false, reason: "Already accepted" });

        quests[quest_id] = {
            quest_id,
            state: "active",
            progress: {},
            accepted_at: new Date().toISOString()
        };
    } else if (action === "complete") {
        const q = quests[quest_id];
        if (!q || q.state !== "active") throw new Error("Quest not active");

        const rewards = QUEST_REWARDS[quest_id];
        if (!rewards) throw new Error("Unknown quest rewards: " + quest_id);

        const delta: Record<string, number> = { coins: rewards.coins, xp: rewards.xp };
        if (rewards.gems) delta["gems"] = rewards.gems;

        try {
            nk.walletUpdate(ctx.userId, delta, { reason: `quest_complete_${quest_id}` });
        } catch (e) {
            logger.error("Failed to award quest rewards: %v", e);
        }

        q.state = "completed";
        q.completed_at = new Date().toISOString();
    } else if (objective_id) {
        const q = quests[quest_id];
        if (!q || q.state !== "active") throw new Error("Quest not active");
        q.progress[objective_id] = (q.progress[objective_id] ?? 0) + value;
    }

    nk.storageWrite([{
        collection: "player_data",
        key: "quests",
        userId: ctx.userId,
        value: quests,
        permissionRead: 1,
        permissionWrite: 0
    }]);

    logger.info("rpcQuestAction: %s quest=%s action=%s", ctx.userId, quest_id, action);
    return JSON.stringify({ success: true, quest: quests[quest_id] });
};

export function rpcGetQuests(
    ctx: nkruntime.Context,
    _logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    _payload: string
): string {
    let quests: Record<string, StoredQuest> = {};
    try {
        const stored = nk.storageRead([{ collection: "player_data", key: "quests", userId: ctx.userId }]);
        if (stored.length > 0) quests = stored[0].value as Record<string, StoredQuest>;
    } catch { /* empty */ }
    return JSON.stringify({ quests });
};

export function register_quest_rpc(
    _ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    _nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {

    logger.info("quest_rpc module initialized");
}
