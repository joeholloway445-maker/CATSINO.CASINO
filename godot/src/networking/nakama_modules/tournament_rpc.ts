// Server-side tournament management
const MAX_PARTICIPANTS = 16;
const ENTRY_FEE_MIN = 100;
const PRIZE_MULTIPLIER = 8;

interface TournamentPayload {
    tournament_id?: string;
    name?: string;
    type?: string;
    entry_fee?: number;
}

const rpcCreateTournament: nkruntime.RpcFunction = function(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    const userRoles: string[] = ctx.clientVars["roles"]
        ? (ctx.clientVars["roles"] as string).split(",")
        : [];
    if (!userRoles.includes("admin")) throw new Error("Unauthorized");

    let data: TournamentPayload;
    try { data = JSON.parse(payload); } catch (e) { throw new Error("Invalid JSON payload"); }

    const { name = "Championship", type = "combat", entry_fee = 500 } = data;
    if (entry_fee < ENTRY_FEE_MIN) throw new Error(`Minimum entry fee: ${ENTRY_FEE_MIN}`);

    const tournamentId = `tournament_${Date.now()}`;
    const tournamentData = {
        id: tournamentId,
        name,
        type,
        entry_fee,
        participants: [],
        prize_pool: 0,
        state: "registration",
        created_at: new Date().toISOString(),
        created_by: ctx.userId
    };

    try {
        nk.storageWrite([{
            collection: "tournaments",
            key: tournamentId,
            userId: "00000000-0000-0000-0000-000000000000",
            value: tournamentData,
            permissionRead: 2,
            permissionWrite: 0
        }]);
    } catch (e) {
        throw new Error("Failed to create tournament");
    }

    logger.info("rpcCreateTournament: %s created tournament %s", ctx.userId, tournamentId);
    return JSON.stringify({ success: true, tournament: tournamentData });
};

const rpcJoinTournament: nkruntime.RpcFunction = function(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: TournamentPayload;
    try { data = JSON.parse(payload); } catch (e) { throw new Error("Invalid JSON payload"); }
    const { tournament_id } = data;
    if (!tournament_id) throw new Error("tournament_id required");

    let stored: nkruntime.StorageObject[] = [];
    try {
        stored = nk.storageRead([{
            collection: "tournaments",
            key: tournament_id,
            userId: "00000000-0000-0000-0000-000000000000"
        }]);
    } catch (e) { throw new Error("Failed to read tournament"); }
    if (stored.length === 0) throw new Error("Tournament not found");

    const t = stored[0].value as {
        id: string; state: string; entry_fee: number;
        participants: string[]; prize_pool: number; name: string; type: string;
        created_at: string; created_by: string;
    };
    if (t.state !== "registration") throw new Error("Tournament not accepting registrations");
    if (t.participants.length >= MAX_PARTICIPANTS) throw new Error("Tournament is full");
    if (t.participants.includes(ctx.userId)) throw new Error("Already registered");

    // Deduct entry fee
    try {
        nk.walletUpdate(ctx.userId, { coins: -t.entry_fee }, {
            reason: `tournament_entry_${tournament_id}`
        });
    } catch (e) {
        throw new Error("Insufficient coins for entry fee");
    }

    t.participants.push(ctx.userId);
    t.prize_pool += t.entry_fee;

    try {
        nk.storageWrite([{
            collection: "tournaments",
            key: tournament_id,
            userId: "00000000-0000-0000-0000-000000000000",
            value: t,
            permissionRead: 2,
            permissionWrite: 0
        }]);
    } catch (e) {
        throw new Error("Failed to update tournament");
    }

    logger.info("rpcJoinTournament: %s joined %s (prize pool: %d)", ctx.userId, tournament_id, t.prize_pool);
    return JSON.stringify({
        success: true,
        tournament_id,
        participant_count: t.participants.length,
        prize_pool: t.prize_pool * PRIZE_MULTIPLIER
    });
};

const rpcGetActiveTournaments: nkruntime.RpcFunction = function(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let tournaments: nkruntime.StorageObject[] = [];
    try {
        const result = nk.storageList("00000000-0000-0000-0000-000000000000", "tournaments", 20, undefined);
        tournaments = result.objects ?? [];
    } catch (e) {
        logger.warn("rpcGetActiveTournaments: %v", e);
    }

    const active = tournaments
        .map(o => o.value as { state: string; id: string; name: string; type: string; entry_fee: number; participants: string[]; prize_pool: number })
        .filter(t => t.state !== "finished")
        .map(t => ({
            id: t.id,
            name: t.name,
            type: t.type,
            entry_fee: t.entry_fee,
            participant_count: t.participants.length,
            max_participants: MAX_PARTICIPANTS,
            prize_pool: t.prize_pool * PRIZE_MULTIPLIER,
            state: t.state,
            is_registered: t.participants.includes(ctx.userId)
        }));

    return JSON.stringify({ tournaments: active });
};

export function register_tournament_rpc(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {
    initializer.registerRpc("create_tournament", rpcCreateTournament);
    initializer.registerRpc("join_tournament", rpcJoinTournament);
    initializer.registerRpc("get_active_tournaments", rpcGetActiveTournaments);
    logger.info("tournament_rpc module initialized");
}
