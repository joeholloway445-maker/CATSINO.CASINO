// Server-authoritative sports prediction — paw ball match outcomes

interface MatchPayload {
    bet?: number;
    pick?: string;  // "home" | "draw" | "away"
    home?: string;
    away?: string;
}

const PAYOUT_TABLE: Record<string, number> = {
    "home": 2,
    "draw": 3,
    "away": 2,
};

function rpcPredictMatch(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: MatchPayload;
    try { data = JSON.parse(payload); } catch { throw new Error("Invalid JSON"); }

    const { bet = 0, pick = "home", home = "Team A", away = "Team B" } = data;

    if (!["home", "draw", "away"].includes(pick)) throw new Error("Invalid pick");

    if (bet > 0) {
        try {
            nk.walletUpdate(ctx.userId, { coins: -bet }, { reason: `sports_bet` });
        } catch { throw new Error("Insufficient coins"); }
    }

    // Simulate match
    const home_score = Math.floor(nk.mathRandom() * 4);
    const away_score = Math.floor(nk.mathRandom() * 4);

    let winner: string;
    if (home_score > away_score) winner = "home";
    else if (away_score > home_score) winner = "away";
    else winner = "draw";

    const correct = winner === pick;
    const payout = correct && bet > 0 ? Math.floor(bet * PAYOUT_TABLE[pick]) : 0;

    if (payout > 0) {
        nk.walletUpdate(ctx.userId, { coins: payout }, { reason: `sports_win` });
    }

    logger.info("rpcPredictMatch: %s pick=%s result=%s payout=%d", ctx.userId, pick, winner, payout);

    return JSON.stringify({
        success: true,
        home,
        away,
        home_score,
        away_score,
        winner,
        player_pick: pick,
        correct,
        payout,
    });
};

export function register_sports_rpc(
    _ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    _nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {
    initializer.registerRpc("predict_match", rpcPredictMatch);
    logger.info("sports_rpc module initialized");
}
