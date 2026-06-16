// Server-side battle pass XP sync and tier claim validation
interface BattlePassPayload {
    xp_amount?: number;
    tier?: number;
    is_premium?: boolean;
}

const FREE_TIER_REWARDS: Record<number, { coins?: number; gems?: number; item?: string; companion?: string }> = {
    1:  { coins: 200 },
    2:  { coins: 300 },
    3:  { companion: "FL001" },
    4:  { coins: 500 },
    5:  { item: "charm_luck" },
    6:  { coins: 750 },
    7:  { gems: 5 },
    8:  { coins: 1000 },
    9:  { companion: "WA001" },
    10: { coins: 2000 },
};

const PREMIUM_TIER_REWARDS: Record<number, { coins?: number; gems?: number; item?: string; companion?: string }> = {
    1:  { coins: 500 },
    2:  { companion: "SC010" },
    3:  { gems: 10 },
    4:  { item: "ring_speed" },
    5:  { coins: 1500 },
    6:  { companion: "VC010" },
    7:  { gems: 20 },
    8:  { item: "goggles_neon" },
    9:  { companion: "SC050" },
    10: { coins: 5000 },
};

const TIER_XP_REQUIREMENTS: number[] = [0, 500, 1200, 2000, 3000, 4200, 5600, 7200, 9000, 11000];

const rpcAddBattlePassXP: nkruntime.RpcFunction = function(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: BattlePassPayload;
    try { data = JSON.parse(payload); } catch { throw new Error("Invalid JSON"); }

    const xp_amount = data.xp_amount ?? 0;
    if (xp_amount <= 0) throw new Error("xp_amount must be positive");

    let bp: { xp: number; claimed_free: number[]; claimed_premium: number[]; has_premium: boolean } = {
        xp: 0, claimed_free: [], claimed_premium: [], has_premium: false
    };

    try {
        const stored = nk.storageRead([{ collection: "player_data", key: "battlepass", userId: ctx.userId }]);
        if (stored.length > 0) bp = stored[0].value as typeof bp;
    } catch { /* fresh */ }

    bp.xp += xp_amount;

    nk.storageWrite([{
        collection: "player_data",
        key: "battlepass",
        userId: ctx.userId,
        value: bp,
        permissionRead: 1,
        permissionWrite: 0
    }]);

    logger.info("rpcAddBattlePassXP: %s +%d xp (total %d)", ctx.userId, xp_amount, bp.xp);
    return JSON.stringify({ success: true, total_xp: bp.xp });
};

const rpcClaimBattlePassTier: nkruntime.RpcFunction = function(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: BattlePassPayload;
    try { data = JSON.parse(payload); } catch { throw new Error("Invalid JSON"); }

    const { tier, is_premium = false } = data;
    if (!tier || tier < 1 || tier > 10) throw new Error("Invalid tier");

    let bp: { xp: number; claimed_free: number[]; claimed_premium: number[]; has_premium: boolean } = {
        xp: 0, claimed_free: [], claimed_premium: [], has_premium: false
    };
    try {
        const stored = nk.storageRead([{ collection: "player_data", key: "battlepass", userId: ctx.userId }]);
        if (stored.length > 0) bp = stored[0].value as typeof bp;
    } catch { /* fresh */ }

    const required_xp = TIER_XP_REQUIREMENTS[tier - 1] ?? 99999;
    if (bp.xp < required_xp) throw new Error(`Need ${required_xp} XP to claim tier ${tier}`);

    if (is_premium && !bp.has_premium) throw new Error("Premium pass not activated");

    const claimedList = is_premium ? bp.claimed_premium : bp.claimed_free;
    if (claimedList.includes(tier)) throw new Error("Tier already claimed");

    const rewards = is_premium ? PREMIUM_TIER_REWARDS[tier] : FREE_TIER_REWARDS[tier];
    if (!rewards) throw new Error("No reward for tier " + tier);

    const walletDelta: Record<string, number> = {};
    if (rewards.coins) walletDelta["coins"] = rewards.coins;
    if (rewards.gems) walletDelta["gems"] = rewards.gems;
    if (Object.keys(walletDelta).length > 0) {
        nk.walletUpdate(ctx.userId, walletDelta, { reason: `battlepass_tier_${tier}` });
    }

    claimedList.push(tier);
    nk.storageWrite([{
        collection: "player_data",
        key: "battlepass",
        userId: ctx.userId,
        value: bp,
        permissionRead: 1,
        permissionWrite: 0
    }]);

    logger.info("rpcClaimBattlePassTier: %s claimed tier %d (%s)", ctx.userId, tier, is_premium ? "premium" : "free");
    return JSON.stringify({ success: true, tier, rewards });
};

export function register_battlepass_rpc(
    _ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    _nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {
    initializer.registerRpc("add_battlepass_xp", rpcAddBattlePassXP);
    initializer.registerRpc("claim_battlepass_tier", rpcClaimBattlePassTier);
    logger.info("battlepass_rpc module initialized");
}
