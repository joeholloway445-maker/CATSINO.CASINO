interface FriendActionPayload {
    target_user_id?: string;
    username?: string;
}

export function rpcAddFriend(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: FriendActionPayload;
    try {
        data = JSON.parse(payload);
    } catch (e) {
        throw new Error("Invalid JSON payload");
    }

    const { target_user_id, username } = data;
    if (!target_user_id && !username) throw new Error("target_user_id or username required");

    let resolvedId = target_user_id;

    if (!resolvedId && username) {
        try {
            const users = nk.usersGetUsername([username]);
            if (!users || users.length === 0) throw new Error(`User '${username}' not found`);
            resolvedId = users[0].userId;
        } catch (e) {
            throw new Error(`Failed to find user '${username}'`);
        }
    }

    try {
        nk.friendsAdd(ctx.userId, ctx.username, [resolvedId!], []);
    } catch (e) {
        logger.error("rpcAddFriend: failed %s -> %s: %v", ctx.userId, resolvedId, e);
        throw new Error("Failed to send friend request");
    }

    logger.info("rpcAddFriend: %s sent request to %s", ctx.userId, resolvedId);
    return JSON.stringify({ success: true, target_user_id: resolvedId });
};

export function rpcRemoveFriend(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: { target_user_id: string };
    try {
        data = JSON.parse(payload);
    } catch (e) {
        throw new Error("Invalid JSON payload");
    }

    const { target_user_id } = data;
    if (!target_user_id) throw new Error("target_user_id required");

    try {
        nk.friendsDelete(ctx.userId, ctx.username, [target_user_id], []);
    } catch (e) {
        logger.error("rpcRemoveFriend: failed %s -> %s: %v", ctx.userId, target_user_id, e);
        throw new Error("Failed to remove friend");
    }

    return JSON.stringify({ success: true, removed_user_id: target_user_id });
};

export function rpcGetFriends(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let friends: nkruntime.FriendList | null = null;
    try {
        friends = nk.friendsList(ctx.userId, 100, undefined, undefined);
    } catch (e) {
        logger.error("rpcGetFriends: failed for user %s: %v", ctx.userId, e);
        throw new Error("Failed to fetch friends");
    }

    const serialized = (friends?.friends ?? []).map(f => ({
        user_id: f.user?.id,
        username: f.user?.username,
        display_name: f.user?.displayName,
        online: f.user?.online ?? false,
        state: f.state // 0=friend, 1=invite sent, 2=invite received, 3=blocked
    }));

    return JSON.stringify({
        friends: serialized,
        total: serialized.length
    });
};

export function register_friend_rpc(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {


    logger.info("friend_rpc module initialized");
}
