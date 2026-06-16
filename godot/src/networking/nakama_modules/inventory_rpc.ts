const InventoryRpc = {
  getInventory: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, _payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");

    const objects = nk.storageRead([
      { collection: "inventory", key: "items", userId }
    ]);

    let items: any[] = [];
    if (objects && objects.length > 0) {
      items = JSON.parse(objects[0].value).items || [];
    }

    return JSON.stringify({ items });
  },

  useItem: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");

    const { item_id } = JSON.parse(payload || "{}");
    if (!item_id) throw new Error("Missing item_id");

    const objects = nk.storageRead([{ collection: "inventory", key: "items", userId }]);
    let items: any[] = [];
    if (objects && objects.length > 0) items = JSON.parse(objects[0].value).items || [];

    const idx = items.findIndex((i: any) => i.item_id === item_id);
    if (idx === -1) throw new Error("Item not found");

    const item = items[idx];
    if (item.quantity <= 1) {
      items.splice(idx, 1);
    } else {
      items[idx].quantity--;
    }

    nk.storageWrite([{
      collection: "inventory",
      key: "items",
      userId,
      value: JSON.stringify({ items }),
      permissionRead: 1,
      permissionWrite: 1
    }]);

    return JSON.stringify({ success: true, item_id, remaining: items[idx]?.quantity ?? 0 });
  },

  grantItem: function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");

    const { item_id, item_type = "consumable", quantity = 1 } = JSON.parse(payload || "{}");
    if (!item_id) throw new Error("Missing item_id");

    const objects = nk.storageRead([{ collection: "inventory", key: "items", userId }]);
    let items: any[] = [];
    if (objects && objects.length > 0) items = JSON.parse(objects[0].value).items || [];

    const existing = items.find((i: any) => i.item_id === item_id);
    if (existing) {
      existing.quantity += quantity;
    } else {
      items.push({ item_id, item_type, quantity, acquired_at: new Date().toISOString() });
    }

    nk.storageWrite([{
      collection: "inventory",
      key: "items",
      userId,
      value: JSON.stringify({ items }),
      permissionRead: 1,
      permissionWrite: 1
    }]);

    return JSON.stringify({ success: true, item_id, quantity });
  }
};

function InitModule(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer): void {
  initializer.registerRpc("get_inventory", InventoryRpc.getInventory);
  initializer.registerRpc("use_item", InventoryRpc.useItem);
  initializer.registerRpc("grant_item", InventoryRpc.grantItem);
  logger.info("Inventory RPC module loaded");
}
