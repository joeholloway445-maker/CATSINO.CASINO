import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

const QUEST_REWARDS: Record<string, { coins: number; xp: number }> = {
  intro_district_tour: { coins: 500, xp: 200 },
  first_battle: { coins: 200, xp: 100 },
  find_sovereign_crown: { coins: 300, xp: 150 },
  neon_alley_racer: { coins: 400, xp: 175 },
  forest_mystery: { coins: 600, xp: 250 },
  companion_collector: { coins: 750, xp: 300 },
  faction_allegiance: { coins: 1000, xp: 400 },
  help_aqua_merchant: { coins: 350, xp: 150 },
  grand_tournament: { coins: 2000, xp: 800 },
  arcade_champion: { coins: 500, xp: 200 },
  fortune_wheel_spin: { coins: 200, xp: 100 },
  daily_spin: { coins: 100, xp: 50 },
  win_3_games: { coins: 300, xp: 150 },
  race_champion: { coins: 800, xp: 350 },
  big_spender: { coins: 1500, xp: 500 },
};

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { data } = await supabase
    .from("quest_progress")
    .select("*")
    .eq("user_id", user.id);

  return NextResponse.json({ quests: data ?? [] });
}

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { quest_id, action } = await req.json();
  if (!quest_id || !action) return NextResponse.json({ error: "Missing fields" }, { status: 400 });

  if (action === "accept") {
    const { error } = await supabase.rpc("accept_quest", { p_quest_id: quest_id });
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true });
  }

  if (action === "complete") {
    const reward = QUEST_REWARDS[quest_id];
    if (!reward) return NextResponse.json({ error: "Unknown quest" }, { status: 400 });

    const { error } = await supabase.rpc("complete_quest", {
      p_quest_id: quest_id,
      p_reward_coins: reward.coins,
      p_reward_xp: reward.xp,
    });
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true, reward });
  }

  return NextResponse.json({ error: "Unknown action" }, { status: 400 });
}
