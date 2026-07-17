// Server-side shop with server-authoritative purchases
import worldShopsData from "../../../world_data/shops.json";

interface WorldShopItem {
    item_id: string;
    name: string;
    type: string;
    price: number;
    description: string;
    emoji: string;
}
interface WorldShop {
    shop_id: string;
    shop_name: string;
    district: string;
    items: WorldShopItem[];
}

const WORLD_SHOPS: WorldShop[] = (worldShopsData as { shops: WorldShop[] }).shops;

// Flat lookup of world-shop items by item_id -> { shop, item } for purchase validation.
const WORLD_ITEM_INDEX: Record<string, { shop: WorldShop; item: WorldShopItem }> = {};
for (const shop of WORLD_SHOPS) {
    for (const item of shop.items) {
        WORLD_ITEM_INDEX[item.item_id] = { shop, item };
    }
}

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

function purchaseWorldItem(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    entry: { shop: WorldShop; item: WorldShopItem }
): string {
    const { shop, item } = entry;

    try {
        nk.walletUpdate(ctx.userId, { coins: -item.price }, { reason: `shop_purchase_${item.item_id}`, shop_id: shop.shop_id });
    } catch {
        throw new Error("Insufficient coins");
    }

    const storageKey = `inventory_${item.type}`;
    let inventory: string[] = [];
    try {
        const stored = nk.storageRead([{ collection: "player_data", key: storageKey, userId: ctx.userId }]);
        if (stored.length > 0) inventory = (stored[0].value as { items: string[] }).items ?? [];
    } catch { /* empty */ }

    inventory.push(item.item_id);
    nk.storageWrite([{
        collection: "player_data",
        key: storageKey,
        userId: ctx.userId,
        value: { items: inventory },
        permissionRead: 1,
        permissionWrite: 0
    }]);

    logger.info("rpcShopPurchase: %s bought world item %s from %s for %d coins", ctx.userId, item.item_id, shop.shop_id, item.price);
    return JSON.stringify({ success: true, item_id: item.item_id, type: item.type, shop_id: shop.shop_id });
}

function rpcShopPurchase(
    ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    nk: nkruntime.Nakama,
    payload: string
): string {
    let data: ShopPayload;
    try { data = JSON.parse(payload); } catch { throw new Error("Invalid JSON"); }

    const { item_id, currency = "coins" } = data;
    if (!item_id) throw new Error("item_id required");

    const worldEntry = WORLD_ITEM_INDEX[item_id];
    if (worldEntry) {
        return purchaseWorldItem(ctx, logger, nk, worldEntry);
    }

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

function rpcGetShopInventory(
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

interface WorldShopQuery {
    shop_id?: string;
    district?: string;
}

function rpcGetWorldShop(
    _ctx: nkruntime.Context,
    _logger: nkruntime.Logger,
    _nk: nkruntime.Nakama,
    payload: string
): string {
    let query: WorldShopQuery = {};
    try { query = payload ? JSON.parse(payload) : {}; } catch { throw new Error("Invalid JSON"); }

    let shops = WORLD_SHOPS;
    if (query.shop_id) shops = shops.filter(s => s.shop_id === query.shop_id);
    else if (query.district) shops = shops.filter(s => s.district === query.district);

    return JSON.stringify({ shops });
};

export function register_shop_rpc(
    _ctx: nkruntime.Context,
    logger: nkruntime.Logger,
    _nk: nkruntime.Nakama,
    initializer: nkruntime.Initializer
): void {
    initializer.registerRpc("shop_purchase", rpcShopPurchase);
    initializer.registerRpc("get_shop_inventory", rpcGetShopInventory);
    initializer.registerRpc("get_world_shop", rpcGetWorldShop);
    logger.info("shop_rpc module initialized");
}
