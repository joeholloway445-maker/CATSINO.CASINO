const EVOLVE_XP_REQUIRED = [0, 1000, 3000, 7000, 15000];
const EVOLVE_STAT_BONUS = { pow: 5, res: 5, spd: 3, lck: 3, sty: 4 };

const CompanionEvolveRpc = {
  feedCompanion: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");

    const { companion_id, xp_amount } = JSON.parse(payload || "{}");
    if (!companion_id || !xp_amount) throw new Error("Missing companion_id or xp_amount");

    const cost = Math.ceil(xp_amount / 10);

    const walletUpdates = [{ userId, changeset: { coins: -cost }, metadata: { reason: "companion_feed" } }];
    nk.walletsUpdate(walletUpdates, true);

    const key = `companion_${companion_id}`;
    const objects = nk.storageRead([{ collection: "companions", key, userId }]);
    let companion: any = { companion_id, xp: 0, level: 1, evolved: false };
    if (objects && objects.length > 0) {
      companion = JSON.parse(objects[0].value);
    }

    companion.xp = (companion.xp || 0) + xp_amount;

    // Check for level up (every 500 xp)
    const newLevel = Math.min(10, Math.floor(companion.xp / 500) + 1);
    const leveledUp = newLevel > companion.level;
    companion.level = newLevel;

    nk.storageWrite([{
      collection: "companions",
      key,
      userId,
      value: JSON.stringify(companion),
      permissionRead: 1,
      permissionWrite: 1
    }]);

    return JSON.stringify({ success: true, companion, leveled_up: leveledUp, cost });
  },

  evolveCompanion: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");

    const { companion_id } = JSON.parse(payload || "{}");
    if (!companion_id) throw new Error("Missing companion_id");

    const key = `companion_${companion_id}`;
    const objects = nk.storageRead([{ collection: "companions", key, userId }]);
    if (!objects || objects.length === 0) throw new Error("Companion not found");

    const companion = JSON.parse(objects[0].value);
    if (companion.level < 10) throw new Error("Companion must be level 10 to evolve");
    if (companion.evolved) throw new Error("Companion already evolved");

    const cost = 5000;
    nk.walletsUpdate([{ userId, changeset: { coins: -cost }, metadata: { reason: "companion_evolve" } }], true);

    companion.evolved = true;
    companion.evolve_bonus = EVOLVE_STAT_BONUS;

    nk.storageWrite([{
      collection: "companions",
      key,
      userId,
      value: JSON.stringify(companion),
      permissionRead: 1,
      permissionWrite: 1
    }]);

    return JSON.stringify({ success: true, companion, cost });
  }
};

export function register_companion_evolve_rpc(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer): void {
  initializer.registerRpc("feed_companion", CompanionEvolveRpc.feedCompanion);
  initializer.registerRpc("evolve_companion", CompanionEvolveRpc.evolveCompanion);
  logger.info("Companion evolve RPC module loaded");
}
