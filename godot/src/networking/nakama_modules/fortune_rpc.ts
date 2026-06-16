const SEGMENTS = [
  { label: "100 coins", value: 100, weight: 20 },
  { label: "250 coins", value: 250, weight: 15 },
  { label: "500 coins", value: 500, weight: 10 },
  { label: "Try Again", value: 0, weight: 25 },
  { label: "1000 coins", value: 1000, weight: 8 },
  { label: "2x Bet", value: -1, weight: 12 },
  { label: "Lose Bet", value: -2, weight: 8 },
  { label: "2500 coins", value: 2500, weight: 4 },
  { label: "Jackpot!", value: 10000, weight: 1 },
  { label: "150 coins", value: 150, weight: 18 },
  { label: "750 coins", value: 750, weight: 7 },
  { label: "50 coins", value: 50, weight: 22 },
];

const TOTAL_WEIGHT = SEGMENTS.reduce((sum, s) => sum + s.weight, 0);

const FortuneRpc = {
  drawFortune: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");

    const { bet } = JSON.parse(payload || "{}");
    if (!bet || bet < 50 || bet > 10000) throw new Error("Invalid bet");

    nk.walletsUpdate([{ userId, changeset: { cat_coins: -bet }, metadata: { reason: "fortune_spin" } }], true);

    let roll = Math.floor(Math.random() * TOTAL_WEIGHT);
    let segment = SEGMENTS[0];
    for (const s of SEGMENTS) {
      roll -= s.weight;
      if (roll < 0) { segment = s; break; }
    }

    let payout = 0;
    if (segment.value > 0) { payout = segment.value; }
    else if (segment.value === -1) { payout = bet * 2; }
    else if (segment.value === -2) { payout = 0; }

    if (payout > 0) {
      nk.walletsUpdate([{ userId, changeset: { cat_coins: payout }, metadata: { reason: "fortune_win", segment: segment.label } }], true);
    }

    const segmentIndex = SEGMENTS.indexOf(segment);
    return JSON.stringify({ segment: segment.label, segment_index: segmentIndex, payout, bet });
  }
};

export function register_fortune_rpc(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer): void {
  initializer.registerRpc("draw_fortune", FortuneRpc.drawFortune);
  logger.info("Fortune wheel RPC module loaded");
}
