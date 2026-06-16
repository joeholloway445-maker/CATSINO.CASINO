const MAX_GUILD_MEMBERS = 50;
const MIN_GUILD_NAME_LEN = 3;
const MAX_GUILD_NAME_LEN = 32;

interface GuildCreatePayload {
    name: string;
    description?: string;
    faction?: string;
    open?: boolean;
}

interface GuildActionPayload {
    guild_id: string;
}

interface GuildInvitePayload {
    guild_id: string;
    target_user_id: string;
}

const rpcCreateGuild: nkruntime.RpcFunction = function(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: GuildCreatePayload;
    try {
        data = JSON.parse(payload);
    } catch (e) {
        throw new Error("Invalid JSON payload");
    }

    const { name, description = "", faction = "Factionless", open = true } = data;

    if (!name || name.length < MIN_GUILD_NAME_LEN || name.length > MAX_GUILD_NAME_LEN) {
        throw new Error(`Guild name must be ${MIN_GUILD_NAME_LEN}-${MAX_GUILD_NAME_LEN} characters`);
    }

    const VALID_FACTIONS = ["Factionless", "SovereignCrown", "VeiledCurrent", "WildlandsAscendant"];
    if (!VALID_FACTIONS.includes(faction)) {
        throw new Error(`Invalid faction: ${faction}`);
    }

    let group: nkruntime.Group;
    try {
        group = nk.groupCreate(
            ctx.userId,
            name,
            ctx.userId,
            "en",
            description,
            "",
            open,
            { faction, founded: new Date().toISOString() },
            MAX_GUILD_MEMBERS
        );
    } catch (e) {
        logger.error("rpcCreateGuild: failed for user %s: %v", ctx.userId, e);
        throw new Error("Failed to create guild — name may already be taken");
    }

    logger.info("rpcCreateGuild: user %s created guild %s (%s)", ctx.userId, name, group.id);

    return JSON.stringify({
        success: true,
        guild_id: group.id,
        name: group.name,
        faction
    });
};

const rpcJoinGuild: nkruntime.RpcFunction = function(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: GuildActionPayload;
    try {
        data = JSON.parse(payload);
    } catch (e) {
        throw new Error("Invalid JSON payload");
    }

    const { guild_id } = data;
    if (!guild_id) throw new Error("guild_id required");

    try {
        nk.groupUserJoin(guild_id, ctx.userId, ctx.username);
    } catch (e) {
        logger.error("rpcJoinGuild: failed for user %s guild %s: %v", ctx.userId, guild_id, e);
        throw new Error("Failed to join guild");
    }

    logger.info("rpcJoinGuild: user %s joined guild %s", ctx.userId, guild_id);
    return JSON.stringify({ success: true, guild_id });
};

const rpcLeaveGuild: nkruntime.RpcFunction = function(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: GuildActionPayload;
    try {
        data = JSON.parse(payload);
    } catch (e) {
        throw new Error("Invalid JSON payload");
    }

    const { guild_id } = data;
    if (!guild_id) throw new Error("guild_id required");

    try {
        nk.groupUserLeave(guild_id, ctx.userId, ctx.username);
    } catch (e) {
        logger.error("rpcLeaveGuild: failed for user %s guild %s: %v", ctx.userId, guild_id, e);
        throw new Error("Failed to leave guild");
    }

    return JSON.stringify({ success: true, guild_id });
};

const rpcGetGuild: nkruntime.RpcFunction = function(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: GuildActionPayload;
    try {
        data = JSON.parse(payload);
    } catch (e) {
        throw new Error("Invalid JSON payload");
    }

    const { guild_id } = data;
    if (!guild_id) throw new Error("guild_id required");

    let groups: nkruntime.Group[];
    try {
        groups = nk.groupsGetId([guild_id]);
    } catch (e) {
        throw new Error("Failed to fetch guild");
    }

    if (!groups || groups.length === 0) {
        throw new Error("Guild not found");
    }

    const group = groups[0];

    let members: nkruntime.GroupUserList | null = null;
    try {
        members = nk.groupUsersList(guild_id, 50, undefined, undefined);
    } catch (e) {
        logger.warn("rpcGetGuild: could not fetch members for %s: %v", guild_id, e);
    }

    return JSON.stringify({
        guild_id: group.id,
        name: group.name,
        description: group.description,
        member_count: group.edgeCount,
        max_members: group.maxCount,
        open: group.open,
        metadata: group.metadata ?? {},
        members: members?.groupUsers?.map(gu => ({
            user_id: gu.user?.id,
            username: gu.user?.displayName || gu.user?.username,
            state: gu.state
        })) ?? []
    });
};

const rpcInviteToGuild: nkruntime.RpcFunction = function(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: GuildInvitePayload;
    try {
        data = JSON.parse(payload);
    } catch (e) {
        throw new Error("Invalid JSON payload");
    }

    const { guild_id, target_user_id } = data;
    if (!guild_id || !target_user_id) throw new Error("guild_id and target_user_id required");

    try {
        nk.groupUsersAdd(guild_id, [{ userId: target_user_id, state: 3 }]);
    } catch (e) {
        logger.error("rpcInviteToGuild: failed invite from %s to %s: %v", ctx.userId, target_user_id, e);
        throw new Error("Failed to send invitation");
    }

    logger.info("rpcInviteToGuild: %s invited %s to guild %s", ctx.userId, target_user_id, guild_id);
    return JSON.stringify({ success: true, invited_user_id: target_user_id, guild_id });
};

function InitModule(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {
    initializer.registerRpc("create_guild", rpcCreateGuild);
    initializer.registerRpc("join_guild", rpcJoinGuild);
    initializer.registerRpc("leave_guild", rpcLeaveGuild);
    initializer.registerRpc("get_guild", rpcGetGuild);
    initializer.registerRpc("invite_to_guild", rpcInviteToGuild);
    logger.info("guild_rpc module initialized");
}
