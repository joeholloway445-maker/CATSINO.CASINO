const nkruntime: nkruntime.Nakama = {} as any;

const ProfileRpc = {
  getProfile: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");

    const objects = nk.storageRead([
      { collection: "profile", key: "data", userId }
    ]);

    let profile = {
      user_id: userId,
      username: ctx.username,
      level: 1,
      xp: 0,
      faction: "none",
      frame: "basic",
      title: "Newcomer",
      wins: 0,
      losses: 0,
      total_wagered: 0,
      created_at: new Date().toISOString()
    };

    if (objects && objects.length > 0) {
      profile = JSON.parse(objects[0].value);
    }

    return JSON.stringify(profile);
  },

  updateProfile: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");

    const data = JSON.parse(payload || "{}");
    const allowedFields = ["username", "title", "frame"];

    const objects = nk.storageRead([
      { collection: "profile", key: "data", userId }
    ]);

    let profile: any = {};
    if (objects && objects.length > 0) {
      profile = JSON.parse(objects[0].value);
    }

    for (const field of allowedFields) {
      if (data[field] !== undefined) {
        profile[field] = data[field];
      }
    }

    nk.storageWrite([{
      collection: "profile",
      key: "data",
      userId,
      value: JSON.stringify(profile),
      permissionRead: 2,
      permissionWrite: 1
    }]);

    return JSON.stringify({ success: true });
  },

  getLeaderboard: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const result = nk.leaderboardRecordsList("global_wins", [], 20, undefined, 0);
    return JSON.stringify({ records: result.records });
  }
};

export function register_profile_rpc(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer): void {
  initializer.registerRpc("get_profile", ProfileRpc.getProfile);
  initializer.registerRpc("update_profile", ProfileRpc.updateProfile);
  initializer.registerRpc("get_leaderboard", ProfileRpc.getLeaderboard);
  logger.info("Profile RPC module loaded");
}
