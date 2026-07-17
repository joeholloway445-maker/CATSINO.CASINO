// Chat channel management via Nakama's built-in channel system
// Districts map to persistent channel IDs

const DISTRICT_CHANNELS: Record<string, string> = {
    "paw_vegas": "district_paw_vegas",
    "neon_alley": "district_neon_alley",
    "cat_coliseum": "district_cat_coliseum",
    "arcade_galaxy": "district_arcade_galaxy",
    "cat_forest": "district_cat_forest",
};

const MAX_MESSAGE_LEN = 500;
const CHAT_HISTORY_LIMIT = 50;

interface ChatPayload {
    channel: string;
    message?: string;
    limit?: number;
}

export function rpcGetChatHistory(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: ChatPayload;
    try {
        data = JSON.parse(payload);
    } catch (e) {
        throw new Error("Invalid JSON payload");
    }

    const { channel, limit = CHAT_HISTORY_LIMIT } = data;
    if (!channel) throw new Error("channel required");

    const resolvedChannel = DISTRICT_CHANNELS[channel] ?? channel;
    const safeLimit = Math.min(limit, CHAT_HISTORY_LIMIT);

    let messages: nkruntime.ChannelMessage[] = [];
    try {
        const result = nk.channelMessagesList(resolvedChannel, safeLimit, true, undefined);
        messages = result.messages ?? [];
    } catch (e) {
        logger.error("rpcGetChatHistory: failed for channel %s: %v", channel, e);
        throw new Error("Failed to get chat history");
    }

    return JSON.stringify({
        channel,
        messages: messages.map(m => ({
            message_id: m.messageId,
            sender_id: m.senderId,
            username: m.username,
            content: m.content,
            created_at: m.createTime
        }))
    });
};

export function rpcSendSystemMessage(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    // Only admins can send system messages
    const userRoles: string[] = ctx.clientVars["roles"]
        ? (ctx.clientVars["roles"] as string).split(",")
        : [];
    if (!userRoles.includes("admin")) {
        throw new Error("Unauthorized");
    }

    let data: { channel: string; message: string };
    try {
        data = JSON.parse(payload);
    } catch (e) {
        throw new Error("Invalid JSON payload");
    }

    const { channel, message } = data;
    if (!channel || !message) throw new Error("channel and message required");
    if (message.length > MAX_MESSAGE_LEN) throw new Error("Message too long");

    const resolvedChannel = DISTRICT_CHANNELS[channel] ?? channel;

    try {
        nk.channelMessageSend(resolvedChannel, { type: "system", text: message });
    } catch (e) {
        logger.error("rpcSendSystemMessage: failed for channel %s: %v", channel, e);
        throw new Error("Failed to send system message");
    }

    logger.info("rpcSendSystemMessage: admin %s sent to %s", ctx.userId, channel);
    return JSON.stringify({ success: true, channel, message });
};

export function rpcGetActiveDistricts(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    // Return district presence counts from storage
    let districtData: nkruntime.StorageObject[] = [];
    try {
        districtData = nk.storageRead([{
            collection: "districts",
            key: "active_counts",
            userId: "00000000-0000-0000-0000-000000000000"
        }]);
    } catch (e) {
        logger.warn("rpcGetActiveDistricts: could not read storage: %v", e);
    }

    const counts = districtData.length > 0
        ? districtData[0].value as Record<string, number>
        : Object.fromEntries(Object.keys(DISTRICT_CHANNELS).map(k => [k, 0]));

    return JSON.stringify({ districts: counts });
};

export function register_chat_rpc(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {


    logger.info("chat_rpc module initialized");
}
