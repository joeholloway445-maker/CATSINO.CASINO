// Server-authoritative scratch card generation

const SYMBOLS = ["🐱", "🌟", "🎭", "🐾", "💎", "🎰"];
const SYMBOL_WEIGHTS = [30, 20, 18, 15, 10, 7];
const TOTAL_WEIGHT = SYMBOL_WEIGHTS.reduce((a, b) => a + b, 0);

const PAYOUT_TABLE: Record<string, number> = {
    "🐱": 2, "🌟": 3, "🎭": 3, "🐾": 5, "💎": 10, "🎰": 20,
};

function weightedPick(nk: nkruntime.Nakama): string {
    const roll = nk.mathRandom() * TOTAL_WEIGHT;
    let acc = 0;
    for (let i = 0; i < SYMBOL_WEIGHTS.length; i++) {
        acc += SYMBOL_WEIGHTS[i];
        if (roll < acc) return SYMBOLS[i];
    }
    return SYMBOLS[0];
}

interface ScratchPayload {
    bet?: number;
}

const rpcBuyScratchCard: nkruntime.RpcFunction = function(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: ScratchPayload;
    try { data = JSON.parse(payload); } catch { throw new Error("Invalid JSON"); }

    const { bet = 50 } = data;
    if (bet <= 0) throw new Error("Invalid bet");

    try {
        nk.walletUpdate(ctx.userId, { coins: -bet }, { reason: "scratch_card_buy" });
    } catch {
        throw new Error("Insufficient coins");
    }

    // Generate 9 cells — small chance of guaranteed 3-of-a-kind for engagement
    const cells: string[] = [];
    const guarantee_win = nk.mathRandom() < 0.35;  // 35% win rate

    if (guarantee_win) {
        const winning_sym = weightedPick(nk);
        // Place 3 guaranteed same + 6 random
        const positions = [0, 1, 2, 3, 4, 5, 6, 7, 8];
        // Shuffle and pick 3 for guaranteed symbol
        for (let i = positions.length - 1; i > 0; i--) {
            const j = Math.floor(nk.mathRandom() * (i + 1));
            [positions[i], positions[j]] = [positions[j], positions[i]];
        }
        const win_positions = new Set(positions.slice(0, 3));
        for (let i = 0; i < 9; i++) {
            cells.push(win_positions.has(i) ? winning_sym : weightedPick(nk));
        }
    } else {
        // Ensure no 3-of-a-kind
        for (let attempt = 0; attempt < 10; attempt++) {
            cells.length = 0;
            for (let i = 0; i < 9; i++) cells.push(weightedPick(nk));
            // Check for 3-of-a-kind
            const counts: Record<string, number> = {};
            for (const s of cells) counts[s] = (counts[s] ?? 0) + 1;
            if (!Object.values(counts).some(c => c >= 3)) break;
        }
    }

    // Calculate payout
    const counts: Record<string, number> = {};
    for (const s of cells) counts[s] = (counts[s] ?? 0) + 1;
    let payout = 0;
    for (const sym in counts) {
        if (counts[sym] >= 3) {
            payout = Math.floor(bet * (PAYOUT_TABLE[sym] ?? 1));
            break;
        }
    }
    if (payout > 0) {
        nk.walletUpdate(ctx.userId, { coins: payout }, { reason: "scratch_card_win" });
    }

    logger.info("rpcBuyScratchCard: %s bet=%d payout=%d", ctx.userId, bet, payout);
    return JSON.stringify({ success: true, cells, payout, is_win: payout > 0 });
};

export function register_scratch_rpc(
    _ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    _nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {
    initializer.registerRpc("buy_scratch_card", rpcBuyScratchCard);
    logger.info("scratch_rpc module initialized");
}
