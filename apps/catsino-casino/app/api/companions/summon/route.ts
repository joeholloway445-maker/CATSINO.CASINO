import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

const RARITY_WEIGHTS = { common: 60, uncommon: 25, rare: 10, epic: 4, legendary: 1 };
const TOTAL_WEIGHT = Object.values(RARITY_WEIGHTS).reduce((a, b) => a + b, 0);
const COST_SINGLE = 300;
const COST_MULTI = 2500;

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

const FACTIONS = Object.keys(FACTION_POOL);

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

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { count = 1, faction = "" } = await req.json();
  if (count !== 1 && count !== 10) return NextResponse.json({ error: "count must be 1 or 10" }, { status: 400 });

  const cost = count === 10 ? COST_MULTI : COST_SINGLE;

  const { error: spendError } = await supabase.rpc("spend_currency", {
    p_currency: "charges",
    p_amount: cost,
  });
  if (spendError) {
    return NextResponse.json({ error: spendError.message }, { status: 400 });
  }

  const results = [];
  for (let i = 0; i < count; i++) {
    const selectedFaction = faction && FACTIONS.includes(faction)
      ? faction
      : FACTIONS[Math.floor(Math.random() * FACTIONS.length)];
    const rarity = rollRarity();
    const companionId = rollCompanion(selectedFaction, rarity);

    await supabase.from("companion_inventory").upsert({
      user_id: user.id,
      companion_id: companionId,
      faction: selectedFaction,
      rarity,
    }, { onConflict: "user_id,companion_id" });

    results.push({ companion_id: companionId, faction: selectedFaction, rarity });
  }

  return NextResponse.json({ companions: results, cost });
}
