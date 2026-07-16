const WalletRpc = {
  getWallet: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, _payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");
    const account = nk.accountGetId(userId);
    const coins = account.wallet.coins ?? account.wallet.cat_coins ?? 0;
    const gems = account.wallet.gems ?? 0;
    return JSON.stringify({
      success: true,
      coins,
      cat_coins: coins,
      gems,
      balances: { coins, gems, cat_coins: coins },
    });
  },

  claimDailyBonus: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, _payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");

    const DAY_REWARDS = [100, 150, 200, 300, 400, 500, 1000, 200, 250, 350, 500, 600, 750, 2000];

    const objects = nk.storageRead([{ collection: "daily", key: "streak", userId }]);
    let streakData = { streak: 0, last_claim: 0 };
    if (objects && objects.length > 0) streakData = JSON.parse(objects[0].value as string);

    const now = Date.now();
    const hoursSince = (now - streakData.last_claim) / 3600000;
    if (hoursSince < 20) throw new Error("Already claimed today");
    if (hoursSince > 48) streakData.streak = 0;

    streakData.streak++;
    streakData.last_claim = now;
    const day = ((streakData.streak - 1) % 14);
    const reward = DAY_REWARDS[day];

    nk.walletsUpdate([{ userId, changeset: { coins: reward }, metadata: { reason: "daily_bonus", day: streakData.streak } }], true);
    nk.storageWrite([{ collection: "daily", key: "streak", userId, value: JSON.stringify(streakData), permissionRead: 1, permissionWrite: 1 }]);

    return JSON.stringify({ success: true, reward, streak: streakData.streak, day: day + 1, coins_granted: reward });
  }
};

export function register_wallet_rpc(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer): void {
  // get_wallet is owned by economy_rpc (last-register wins). Only register
  // the legacy claim_daily_bonus alias here; daily_bonus lives on economy_rpc.
  initializer.registerRpc("claim_daily_bonus", WalletRpc.claimDailyBonus);
  logger.info("Wallet RPC module loaded (claim_daily_bonus)");
}
