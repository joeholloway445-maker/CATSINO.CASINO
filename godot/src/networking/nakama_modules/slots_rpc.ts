// Server-authoritative slot machine — no client-side RNG
const SYMBOLS = ["🐱", "🌟", "🎭", "🐾", "💎", "🎰", "⭐", "🔔"];
const SYMBOL_WEIGHTS = [30, 20, 20, 15, 8, 4, 2, 1];
const TOTAL_WEIGHT = SYMBOL_WEIGHTS.reduce((a, b) => a + b, 0);

function weightedRandom(nk: nkruntime.Nakama): number {
    const roll = nk.mathRandom() * TOTAL_WEIGHT;
    let acc = 0;
    for (let i = 0; i < SYMBOL_WEIGHTS.length; i++) {
        acc += SYMBOL_WEIGHTS[i];
        if (roll < acc) return i;
    }
    return SYMBOLS.length - 1;
}

const PAYOUTS: Record<string, number> = {
    "🐱🐱🐱": 3,
    "🌟🌟🌟": 5,
    "🎭🎭🎭": 5,
    "🐾🐾🐾": 8,
    "💎💎💎": 15,
    "🎰🎰🎰": 25,
    "⭐⭐⭐": 50,
    "🔔🔔🔔": 100,
    "🐱🐱":   1,  // 2 of a kind - partial match
};

interface SlotsPayload {
    bet?: number;
    game?: string;
}

const rpcSpinSlots: nkruntime.RpcFunction = function(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: SlotsPayload;
    try { data = JSON.parse(payload); } catch { throw new Error("Invalid JSON"); }

    const { bet = 50, game = "slots" } = data;
    if (bet <= 0) throw new Error("Invalid bet amount");

    try {
        nk.walletUpdate(ctx.userId, { coins: -bet }, { reason: `slot_spin_${game}` });
    } catch {
        throw new Error("Insufficient coins");
    }

    const s1 = SYMBOLS[weightedRandom(nk)];
    const s2 = SYMBOLS[weightedRandom(nk)];
    const s3 = SYMBOLS[weightedRandom(nk)];
    const combo = `${s1}${s2}${s3}`;

    let multiplier = 0;
    if (PAYOUTS[combo]) {
        multiplier = PAYOUTS[combo];
    } else if (s1 === s2 || s2 === s3) {
        multiplier = 1; // 2 of a kind
    }

    const payout = Math.floor(bet * multiplier);
    if (payout > 0) {
        nk.walletUpdate(ctx.userId, { coins: payout }, { reason: `slot_win_${game}` });
    }

    logger.info("rpcSpinSlots: %s bet=%d symbols=%s mult=%d payout=%d",
        ctx.userId, bet, combo, multiplier, payout);

    return JSON.stringify({
        success: true,
        symbols: [s1, s2, s3],
        multiplier,
        payout,
        is_win: payout > 0,
    });
};

export function register_slots_rpc(
    _ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    _nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {
    initializer.registerRpc("spin_slots", rpcSpinSlots);
    logger.info("slots_rpc module initialized");
}
