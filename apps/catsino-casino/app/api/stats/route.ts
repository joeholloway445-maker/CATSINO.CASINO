import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const [
    { data: wallet },
    { data: profile },
    { data: recentSpins },
    { data: gameStats },
  ] = await Promise.all([
    supabase.from("wallets").select("coins, gems").eq("user_id", user.id).single(),
    supabase.from("profiles").select("username, level, total_xp, total_winnings, faction").eq("id", user.id).single(),
    supabase.from("spin_results").select("game, bet, payout, created_at").eq("user_id", user.id).order("created_at", { ascending: false }).limit(20),
    supabase.from("game_stats").select("game, bet, payout, result").eq("user_id", user.id).limit(100),
  ]);

  // Calculate per-game stats
  const perGame: Record<string, { plays: number; wins: number; total_wagered: number; total_won: number }> = {};
  for (const row of gameStats ?? []) {
    if (!perGame[row.game]) perGame[row.game] = { plays: 0, wins: 0, total_wagered: 0, total_won: 0 };
    perGame[row.game].plays++;
    if (row.payout > row.bet) perGame[row.game].wins++;
    perGame[row.game].total_wagered += row.bet ?? 0;
    perGame[row.game].total_won += row.payout ?? 0;
  }

  return NextResponse.json({
    wallet: wallet ?? { coins: 0, gems: 0 },
    profile: profile ?? {},
    recent_spins: recentSpins ?? [],
    per_game: perGame,
  });
}
