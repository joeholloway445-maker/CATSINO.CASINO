// Server-side companion management: unlock, evolve, equip roster
const MAX_ACTIVE_ROSTER = 6;
const EVOLVE_COST_COINS = 500;
const EVOLVE_COST_GEMS = 0; // coins only

interface CompanionActionPayload {
    companion_id: string;
}

interface EquipRosterPayload {
    companion_ids: string[];
}

function rpcUnlockCompanion(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: CompanionActionPayload;
    try {
        data = JSON.parse(payload);
    } catch (e) {
        throw new Error("Invalid JSON payload");
    }

    const { companion_id } = data;
    if (!companion_id) throw new Error("companion_id required");

    // Check if already unlocked
    let existing: nkruntime.StorageObject[] = [];
    try {
        existing = nk.storageRead([{
            collection: "companions",
            key: companion_id,
            userId: ctx.userId
        }]);
    } catch (e) {
        logger.warn("rpcUnlockCompanion: storage read error: %v", e);
    }

    if (existing.length > 0) {
        return JSON.stringify({ success: false, reason: "Already unlocked", companion_id });
    }

    const companionData = {
        companion_id,
        unlocked_at: new Date().toISOString(),
        level: 1,
        evolution: 0,
        milestones_reached: [],
        battle_count: 0,
        win_count: 0
    };

    try {
        nk.storageWrite([{
            collection: "companions",
            key: companion_id,
            userId: ctx.userId,
            value: companionData,
            permissionRead: 1,
            permissionWrite: 0
        }]);
    } catch (e) {
        logger.error("rpcUnlockCompanion: write failed for %s: %v", ctx.userId, e);
        throw new Error("Failed to unlock companion");
    }

    logger.info("rpcUnlockCompanion: %s unlocked %s", ctx.userId, companion_id);
    return JSON.stringify({ success: true, companion_id, data: companionData });
};

function rpcEvolveCompanion(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: CompanionActionPayload;
    try {
        data = JSON.parse(payload);
    } catch (e) {
        throw new Error("Invalid JSON payload");
    }

    const { companion_id } = data;
    if (!companion_id) throw new Error("companion_id required");

    let existing: nkruntime.StorageObject[] = [];
    try {
        existing = nk.storageRead([{
            collection: "companions",
            key: companion_id,
            userId: ctx.userId
        }]);
    } catch (e) {
        throw new Error("Failed to read companion data");
    }

    if (existing.length === 0) throw new Error("Companion not unlocked");

    const companionData = existing[0].value as {
        evolution: number; level: number; companion_id: string;
        unlocked_at: string; milestones_reached: string[]; battle_count: number; win_count: number;
    };
    if (companionData.evolution >= 3) throw new Error("Already at max evolution");

    // Deduct cost
    const wallet = nk.walletUpdate(ctx.userId, { coins: -EVOLVE_COST_COINS }, {
        reason: `evolve_companion_${companion_id}`
    });

    if (!wallet) throw new Error("Insufficient coins for evolution");

    companionData.evolution += 1;

    try {
        nk.storageWrite([{
            collection: "companions",
            key: companion_id,
            userId: ctx.userId,
            value: companionData,
            permissionRead: 1,
            permissionWrite: 0
        }]);
    } catch (e) {
        logger.error("rpcEvolveCompanion: write failed: %v", e);
        throw new Error("Failed to save evolution");
    }

    logger.info("rpcEvolveCompanion: %s evolved %s to stage %d", ctx.userId, companion_id, companionData.evolution);
    return JSON.stringify({
        success: true,
        companion_id,
        new_evolution: companionData.evolution,
        cost_paid: EVOLVE_COST_COINS
    });
};

function rpcEquipRoster(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: EquipRosterPayload;
    try {
        data = JSON.parse(payload);
    } catch (e) {
        throw new Error("Invalid JSON payload");
    }

    const { companion_ids } = data;
    if (!Array.isArray(companion_ids)) throw new Error("companion_ids must be an array");
    if (companion_ids.length > MAX_ACTIVE_ROSTER) {
        throw new Error(`Max ${MAX_ACTIVE_ROSTER} companions in active roster`);
    }

    // Verify all are unlocked
    if (companion_ids.length > 0) {
        let stored: nkruntime.StorageObject[] = [];
        try {
            stored = nk.storageRead(companion_ids.map(id => ({
                collection: "companions",
                key: id,
                userId: ctx.userId
            })));
        } catch (e) {
            throw new Error("Failed to verify companion ownership");
        }
        if (stored.length !== companion_ids.length) {
            throw new Error("One or more companions not unlocked");
        }
    }

    try {
        nk.storageWrite([{
            collection: "player_data",
            key: "active_roster",
            userId: ctx.userId,
            value: { companion_ids, updated_at: new Date().toISOString() },
            permissionRead: 1,
            permissionWrite: 0
        }]);
    } catch (e) {
        throw new Error("Failed to save roster");
    }

    return JSON.stringify({ success: true, active_roster: companion_ids });
};

function rpcGetMyCompanions(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let allCompanions: nkruntime.StorageObject[] = [];
    let cursor: string | undefined = undefined;

    do {
        const result = nk.storageList(ctx.userId, "companions", 100, cursor);
        allCompanions = allCompanions.concat(result.objects ?? []);
        cursor = result.cursor;
    } while (cursor);

    let rosterData: nkruntime.StorageObject[] = [];
    try {
        rosterData = nk.storageRead([{
            collection: "player_data",
            key: "active_roster",
            userId: ctx.userId
        }]);
    } catch (e) {}

    const activeRoster = rosterData.length > 0
        ? (rosterData[0].value as { companion_ids: string[] }).companion_ids
        : [];

    return JSON.stringify({
        companions: allCompanions.map(o => ({ id: o.key, ...o.value })),
        active_roster: activeRoster,
        total_unlocked: allCompanions.length
    });
};

export function register_companion_rpc(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {
    initializer.registerRpc("unlock_companion", rpcUnlockCompanion);
    // evolve_companion is owned by companion_evolve_rpc (feed + evolve).
    initializer.registerRpc("equip_roster", rpcEquipRoster);
    initializer.registerRpc("get_my_companions", rpcGetMyCompanions);
    logger.info("companion_rpc module initialized");
}
