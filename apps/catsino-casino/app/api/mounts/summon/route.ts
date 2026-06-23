import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

const RARITY_WEIGHTS = { common: 60, uncommon: 25, rare: 10, epic: 4, legendary: 1 };
const TOTAL_WEIGHT = Object.values(RARITY_WEIGHTS).reduce((a, b) => a + b, 0);
const COST_SINGLE = 300;
const COST_MULTI = 2500;

const FACTION_POOL: Record<string, Record<string, string[]>> = {
  SovereignCrown: {
    legendary: ["SC_MOUNT_025", "SC_MOUNT_050"],
    epic: ["SC_MOUNT_015", "SC_MOUNT_030"],
    rare: ["SC_MOUNT_010", "SC_MOUNT_020"],
    uncommon: ["SC_MOUNT_005", "SC_MOUNT_012"],
    common: ["SC_MOUNT_001", "SC_MOUNT_002"],
  },
  WildlandsAscendant: {
    legendary: ["WA_MOUNT_025", "WA_MOUNT_050"],
    epic: ["WA_MOUNT_015", "WA_MOUNT_030"],
    rare: ["WA_MOUNT_010", "WA_MOUNT_020"],
    uncommon: ["WA_MOUNT_005", "WA_MOUNT_012"],
    common: ["WA_MOUNT_001", "WA_MOUNT_002"],
  },
  VeiledCurrent: {
    legendary: ["VC_MOUNT_025", "VC_MOUNT_050"],
    epic: ["VC_MOUNT_015", "VC_MOUNT_030"],
    rare: ["VC_MOUNT_010", "VC_MOUNT_020"],
    uncommon: ["VC_MOUNT_005", "VC_MOUNT_012"],
    common: ["VC_MOUNT_001", "VC_MOUNT_002"],
  },
  Factionless: {
    legendary: ["FL_MOUNT_025", "FL_MOUNT_050"],
    epic: ["FL_MOUNT_015", "FL_MOUNT_030"],
    rare: ["FL_MOUNT_010", "FL_MOUNT_020"],
    uncommon: ["FL_MOUNT_005", "FL_MOUNT_012"],
    common: ["FL_MOUNT_001", "FL_MOUNT_002"],
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

function rollMount(faction: string, rarity: string): string {
  const pool = FACTION_POOL[faction]?.[rarity] ?? FACTION_POOL.Factionless[rarity] ?? ["FL_MOUNT_001"];
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
    const mountId = rollMount(selectedFaction, rarity);

    await supabase.from("mount_inventory").upsert({
      user_id: user.id,
      mount_id: mountId,
      faction: selectedFaction,
      rarity,
    }, { onConflict: "user_id,mount_id" });

    results.push({ mount_id: mountId, faction: selectedFaction, rarity });
  }

  return NextResponse.json({ mounts: results, cost });
}
