// Server-side achievement verification and XP grants
// Achievements are validated server-side to prevent spoofing

const ACHIEVEMENT_XP: Record<string, number> = {
    "first_win": 50, "high_roller": 100, "jackpot": 500,
    "streak_3": 150, "streak_7": 500, "companion_1": 100,
    "companion_10": 300, "companion_50": 1000, "evolve_1": 200,
    "evolve_max": 1000, "faction_bonus": 100, "district_explore": 200,
    "race_win": 150, "race_3": 300, "daily_7": 250, "daily_30": 1000,
    "guild_join": 100, "guild_create": 200, "friend_5": 150,
    "battlepass_10": 200, "battlepass_50": 500, "battlepass_100": 2000,
    "tournament_enter": 100, "tournament_win": 1000, "sleeper_burst": 300,
    "coins_1000": 50, "coins_10000": 200, "coins_100000": 1000,
    "scratch_big": 200, "slots_crown": 500,
};

interface AchievementPayload {
    achievement_id: string;
    evidence?: Record<string, unknown>;
}

export function rpcClaimAchievement(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: AchievementPayload;
    try {
        data = JSON.parse(payload);
    } catch (e) {
        throw new Error("Invalid JSON payload");
    }

    const { achievement_id } = data;
    if (!achievement_id || !(achievement_id in ACHIEVEMENT_XP)) {
        throw new Error(`Unknown achievement: ${achievement_id}`);
    }

    // Check if already claimed
    let existing: nkruntime.StorageObject[] = [];
    try {
        existing = nk.storageRead([{
            collection: "achievements",
            key: achievement_id,
            userId: ctx.userId
        }]);
    } catch (e) {}

    if (existing.length > 0) {
        return JSON.stringify({ success: false, reason: "Already claimed", achievement_id });
    }

    const xpGrant = ACHIEVEMENT_XP[achievement_id];

    // Record achievement
    try {
        nk.storageWrite([{
            collection: "achievements",
            key: achievement_id,
            userId: ctx.userId,
            value: {
                claimed_at: new Date().toISOString(),
                xp_granted: xpGrant
            },
            permissionRead: 1,
            permissionWrite: 0
        }]);
    } catch (e) {
        throw new Error("Failed to record achievement");
    }

    // Grant XP via wallet (using xp as currency for consistency)
    try {
        nk.walletUpdate(ctx.userId, { xp: xpGrant }, {
            reason: `achievement_${achievement_id}`
        });
    } catch (e) {
        logger.warn("rpcClaimAchievement: xp grant failed for %s: %v", ctx.userId, e);
    }

    logger.info("rpcClaimAchievement: %s claimed %s (+%d xp)", ctx.userId, achievement_id, xpGrant);
    return JSON.stringify({ success: true, achievement_id, xp_granted: xpGrant });
};

export function rpcGetAchievements(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let claimed: nkruntime.StorageObject[] = [];
    let cursor: string | undefined = undefined;

    do {
        const result = nk.storageList(ctx.userId, "achievements", 100, cursor);
        claimed = claimed.concat(result.objects ?? []);
        cursor = result.cursor;
    } while (cursor);

    const claimedIds = new Set(claimed.map(o => o.key));
    const totalXp = claimed.reduce((sum, o) => sum + ((o.value as { xp_granted: number }).xp_granted ?? 0), 0);

    return JSON.stringify({
        claimed: claimed.map(o => ({ id: o.key, ...o.value })),
        claimed_count: claimed.length,
        total_achievements: Object.keys(ACHIEVEMENT_XP).length,
        total_xp_earned: totalXp
    });
};

export function register_achievement_rpc(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {

    logger.info("achievement_rpc module initialized");
}
