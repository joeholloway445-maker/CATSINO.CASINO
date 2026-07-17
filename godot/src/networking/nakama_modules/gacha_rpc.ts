// Companion gacha/summon system — all RNG server-authoritative
const RARITY_WEIGHTS = { common: 60, uncommon: 25, rare: 10, epic: 4, legendary: 1 };
const TOTAL_WEIGHT = Object.values(RARITY_WEIGHTS).reduce((a, b) => a + b, 0);
const COST_SINGLE = 300;
const COST_MULTI = 2500; // 10-pull discount

const FACTION_POOL: Record<string, Record<string, string[]>> = {
  SovereignCrown: {
    legendary: ["SC025", "SC050", "SC075", "SC100", "SC125", "SC150"],
    epic: ["SC015", "SC030", "SC045", "SC060", "SC085", "SC110", "SC135"],
    rare: ["SC010", "SC020", "SC040", "SC065", "SC080", "SC095", "SC120"],
    uncommon: ["SC005", "SC012", "SC022", "SC035", "SC055", "SC070", "SC090"],
    common: ["SC001", "SC002", "SC003", "SC004", "SC006", "SC007", "SC008"],
  },
  WildlandsAscendant: {
    legendary: ["WA025", "WA050", "WA075", "WA100", "WA125", "WA150"],
    epic: ["WA015", "WA030", "WA045", "WA060", "WA085", "WA110", "WA135"],
    rare: ["WA010", "WA020", "WA040", "WA065", "WA080", "WA095", "WA120"],
    uncommon: ["WA005", "WA012", "WA022", "WA035", "WA055", "WA070", "WA090"],
    common: ["WA001", "WA002", "WA003", "WA004", "WA006", "WA007", "WA008"],
  },
  VeiledCurrent: {
    legendary: ["VC025", "VC050", "VC075", "VC100", "VC125", "VC150"],
    epic: ["VC015", "VC030", "VC045", "VC060", "VC085", "VC110", "VC135"],
    rare: ["VC010", "VC020", "VC040", "VC065", "VC080", "VC095", "VC120"],
    uncommon: ["VC005", "VC012", "VC022", "VC035", "VC055", "VC070", "VC090"],
    common: ["VC001", "VC002", "VC003", "VC004", "VC006", "VC007", "VC008"],
  },
  Factionless: {
    legendary: ["FL027", "FL050", "FL075", "FL100", "FL127", "FL150"],
    epic: ["FL015", "FL030", "FL045", "FL070", "FL090", "FL115", "FL135"],
    rare: ["FL010", "FL020", "FL040", "FL060", "FL080", "FL095", "FL118"],
    uncommon: ["FL005", "FL012", "FL022", "FL035", "FL055", "FL076", "FL110"],
    common: ["FL001", "FL002", "FL003", "FL004", "FL006", "FL007", "FL008"],
  },
};

function rollRarity(): string {
  let roll = Math.floor(Math.random() * TOTAL_WEIGHT);
  for (const [rarity, weight] of Object.entries(RARITY_WEIGHTS)) {
    roll -= weight;
    if (roll < 0) return rarity;
  }
  return "common";
}

function rollCompanion(faction: string, rarity: string): string {
  const pool = FACTION_POOL[faction]?.[rarity] ?? FACTION_POOL.Factionless[rarity] ?? ["FL001"];
  return pool[Math.floor(Math.random() * pool.length)];
}

function pickFaction(input: string): string {
  const valid = ["SovereignCrown", "WildlandsAscendant", "VeiledCurrent", "Factionless"];
  return valid.includes(input) ? input : valid[Math.floor(Math.random() * valid.length)];
}

function summonCompanion(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string): string {
    const userId = ctx.userId;
    if (!userId) throw new Error("Not authenticated");

    const { count = 1, faction = "" } = JSON.parse(payload || "{}");
    if (count !== 1 && count !== 10) throw new Error("count must be 1 or 10");

    const cost = count === 10 ? COST_MULTI : COST_SINGLE;
    nk.walletsUpdate([{ userId, changeset: { coins: -cost }, metadata: { reason: "gacha_summon", count } }], true);

    const results = [];
    for (let i = 0; i < count; i++) {
      const selectedFaction = faction ? pickFaction(faction) : pickFaction(["SovereignCrown", "WildlandsAscendant", "VeiledCurrent", "Factionless"][Math.floor(Math.random() * 4)]);
      const rarity = rollRarity();
      const companionId = rollCompanion(selectedFaction, rarity);

      nk.storageWrite([{
        collection: "companion_collection",
        key: companionId,
        userId,
        value: JSON.stringify({ companion_id: companionId, faction: selectedFaction, rarity, acquired_at: new Date().toISOString() }),
        permissionRead: 1,
        permissionWrite: 1
      }]);

      results.push({ companion_id: companionId, faction: selectedFaction, rarity });
    }

    return JSON.stringify({ companions: results, cost });
  }


export function register_gacha_rpc(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer): void {
  initializer.registerRpc("summon_companion", summonCompanion);
  logger.info("Gacha RPC module loaded");
}
