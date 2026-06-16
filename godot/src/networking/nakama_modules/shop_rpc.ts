// Server-side shop with server-authoritative purchases
const SHOP_ITEMS: Record<string, { price_coins: number; price_gems: number; type: string; value: number }> = {
    "speed_boost_1h": { price_coins: 500, price_gems: 0, type: "boost", value: 3600 },
    "luck_boost_1h":  { price_coins: 500, price_gems: 0, type: "boost", value: 3600 },
    "companion_slot": { price_coins: 0,   price_gems: 50, type: "slot", value: 1 },
    "coin_pack_1k":   { price_coins: 0,   price_gems: 10, type: "coins", value: 1000 },
    "coin_pack_5k":   { price_coins: 0,   price_gems: 45, type: "coins", value: 5000 },
    "coin_pack_15k":  { price_coins: 0,   price_gems: 120, type: "coins", value: 15000 },
    "daily_token":    { price_coins: 200, price_gems: 0,  type: "consumable", value: 1 },
    "potion_speed":   { price_coins: 150, price_gems: 0,  type: "consumable", value: 1 },
    "potion_power":   { price_coins: 150, price_gems: 0,  type: "consumable", value: 1 },
    "elixir_luck":    { price_coins: 400, price_gems: 0,  type: "consumable", value: 1 },
    "treat_basic":    { price_coins: 100, price_gems: 0,  type: "companion_item", value: 1 },
    "bond_crystal":   { price_coins: 0,   price_gems: 30, type: "companion_item", value: 1 },
    "charm_luck":     { price_coins: 200, price_gems: 0,  type: "equipment", value: 1 },
    "ring_speed":     { price_coins: 500, price_gems: 0,  type: "equipment", value: 1 },
    "goggles_neon":   { price_coins: 800, price_gems: 0,  type: "equipment", value: 1 },
    "vest_basic":     { price_coins: 100, price_gems: 0,  type: "equipment", value: 1 },
    "claw_basic":     { price_coins: 100, price_gems: 0,  type: "equipment", value: 1 },
};

interface ShopPayload {
    item_id?: string;
    currency?: string;
}

const rpcShopPurchase: nkruntime.RpcFunction = function(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: ShopPayload;
    try { data = JSON.parse(payload); } catch { throw new Error("Invalid JSON"); }

    const { item_id, currency = "coins" } = data;
    if (!item_id) throw new Error("item_id required");

    const item = SHOP_ITEMS[item_id];
    if (!item) throw new Error("Unknown item: " + item_id);

    const cost = currency === "gems" ? item.price_gems : item.price_coins;
    if (cost <= 0 && currency === "gems" && item.price_gems === 0)
        throw new Error("Item cannot be purchased with gems");
    if (cost <= 0 && currency === "coins" && item.price_coins === 0)
        throw new Error("Item cannot be purchased with coins");

    const delta: Record<string, number> = {};
    delta[currency] = -cost;

    if (item.type === "coins") {
        delta["coins"] = (delta["coins"] ?? 0) + item.value;
    }

    try {
        nk.walletUpdate(ctx.userId, delta, { reason: `shop_purchase_${item_id}` });
    } catch {
        throw new Error("Insufficient " + currency);
    }

    if (item.type !== "coins") {
        const storageKey = `inventory_${item.type}`;
        let inventory: string[] = [];
        try {
            const stored = nk.storageRead([{ collection: "player_data", key: storageKey, userId: ctx.userId }]);
            if (stored.length > 0) inventory = (stored[0].value as { items: string[] }).items ?? [];
        } catch { /* empty */ }

        inventory.push(item_id);
        nk.storageWrite([{
            collection: "player_data",
            key: storageKey,
            userId: ctx.userId,
            value: { items: inventory },
            permissionRead: 1,
            permissionWrite: 0
        }]);
    }

    logger.info("rpcShopPurchase: %s bought %s for %d %s", ctx.userId, item_id, cost, currency);
    return JSON.stringify({ success: true, item_id, type: item.type });
};

const rpcGetShopInventory: nkruntime.RpcFunction = function(
    ctx: nkruntime.Context,
    _logger: nkruntime.Logger,
    _nk: nkruntime.Nakama,
    _payload: string
): string {
    const catalog = Object.entries(SHOP_ITEMS).map(([id, item]) => ({
        id,
        price_coins: item.price_coins,
        price_gems: item.price_gems,
        type: item.type,
    }));
    return JSON.stringify({ items: catalog });
};

export function register_shop_rpc(
    _ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    _nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {
    initializer.registerRpc("shop_purchase", rpcShopPurchase);
    initializer.registerRpc("get_shop_inventory", rpcGetShopInventory);
    logger.info("shop_rpc module initialized");
}
