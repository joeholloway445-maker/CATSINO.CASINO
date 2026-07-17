// Server-authoritative race resolution — no client-side cheating
const TRACK_SEGMENTS = 10;
const BASE_SEGMENT_TIME = 1.0;

interface RacePayload {
    race_id?: string;
    frame_id?: string;
    mod_id?: string;
    race_type?: string;
    bet?: number;
}

interface RacerStats {
    spd: number; lck: number; pow: number; res: number;
}

function rollRng(nk: nkruntime.Nakama): number {
    return nk.mathRandom();
}

function resolveSegment(racer: RacerStats, nk: nkruntime.Nakama): number {
    const base = BASE_SEGMENT_TIME;
    const spdFactor = 1 - (racer.spd / 1000);
    const luckRoll = (rollRng(nk) * racer.lck) / 500;
    return Math.max(0.3, base * spdFactor - luckRoll);
}

const FRAME_STATS: Record<string, RacerStats> = {
    "veil":    { spd: 115, lck: 100, pow: 80,  res: 70 },
    "zephyr":  { spd: 112, lck: 108, pow: 75,  res: 70 },
    "bolt":    { spd: 120, lck: 80,  pow: 84,  res: 65 },
    "bastion": { spd: 75,  lck: 80,  pow: 110, res: 120 },
    "tremor":  { spd: 80,  lck: 80,  pow: 118, res: 108 },
    "surge":   { spd: 85,  lck: 85,  pow: 120, res: 80  },
};

const RACE_PAYOUT: Record<number, number> = { 1: 3, 2: 1.5, 3: 1.0 };

function rpcStartRace(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: RacePayload;
    try { data = JSON.parse(payload); } catch { throw new Error("Invalid JSON"); }

    const { frame_id = "veil", bet = 0, race_type = "standard" } = data;

    if (bet > 0) {
        try {
            nk.walletUpdate(ctx.userId, { coins: -bet }, { reason: `race_entry_${race_type}` });
        } catch { throw new Error("Insufficient coins"); }
    }

    const playerStats = FRAME_STATS[frame_id] ?? { spd: 90, lck: 90, pow: 90, res: 90 };

    // 7 AI opponents → 8-racer field (matches RaceUI rows + OfflineCasino)
    const opponents = ["npc_bolt", "npc_phantom", "npc_crimson", "npc_veil", "npc_surge", "npc_zephyr", "npc_bastion"];
    const oppFrames = ["bolt", "veil", "tremor", "zephyr", "surge", "bastion", "bolt"];

    const racers: Array<{ id: string; time: number; position: number }> = [];

    let playerTime = 0;
    for (let i = 0; i < TRACK_SEGMENTS; i++) playerTime += resolveSegment(playerStats, nk);
    racers.push({ id: "YOU", time: playerTime, position: 0 });

    for (let a = 0; a < opponents.length; a++) {
        const stats = FRAME_STATS[oppFrames[a]] ?? { spd: 90, lck: 90, pow: 90, res: 90 };
        let t = 0;
        for (let i = 0; i < TRACK_SEGMENTS; i++) t += resolveSegment(stats, nk);
        racers.push({ id: opponents[a], time: t, position: 0 });
    }

    racers.sort((a, b) => a.time - b.time);
    racers.forEach((r, i) => { r.position = i + 1; });

    const playerResult = racers.find(r => r.id === "YOU")!;
    const payout = bet > 0 ? Math.floor(bet * (RACE_PAYOUT[playerResult.position] ?? 0)) : 0;

    if (payout > 0) {
        nk.walletUpdate(ctx.userId, { coins: payout }, { reason: `race_win_${race_type}` });
    }

    logger.info("rpcStartRace: %s placed %d (time %.2fs) bet=%d payout=%d",
        ctx.userId, playerResult.position, playerResult.time, bet, payout);

    return JSON.stringify({
        success: true,
        position: playerResult.position,
        finish_time: playerResult.time.toFixed(2),
        results: racers.map(r => ({ id: r.id, position: r.position, time: r.time.toFixed(2) })),
        payout,
        server_wallet: true,
    });
};

export function register_race_rpc(
    _ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    _nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {
    initializer.registerRpc("start_race", rpcStartRace);
    logger.info("race_rpc module initialized");
}
