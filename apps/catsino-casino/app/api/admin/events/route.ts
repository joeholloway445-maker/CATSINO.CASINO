import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

const LIVE_EVENTS = [
  { id: "jackpot_hour", name: "Jackpot Hour", description: "2x slot payouts", multiplier: 2.0 },
  { id: "double_xp", name: "Double XP", description: "2x XP from all games", multiplier: 2.0 },
  { id: "faction_war", name: "Faction War", description: "Faction combat bonuses active", multiplier: 1.5 },
  { id: "lucky_weekend", name: "Lucky Weekend", description: "+20 LCK for all players", multiplier: 1.0 },
  { id: "race_championship", name: "Race Championship", description: "3x race payouts", multiplier: 3.0 },
  { id: "companion_festival", name: "Companion Festival", description: "Rare companions available", multiplier: 1.0 },
  { id: "high_roller", name: "High Roller Night", description: "Max bet limits doubled", multiplier: 1.0 },
];

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { data: profile } = await supabase
    .from("profiles")
    .select("is_admin")
    .eq("id", user.id)
    .single();

  if (!profile?.is_admin) return NextResponse.json({ error: "Forbidden" }, { status: 403 });

  const { data: events } = await supabase
    .from("active_events")
    .select("*")
    .gte("ends_at", new Date().toISOString());

  return NextResponse.json({ events: events ?? [], available: LIVE_EVENTS });
}

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { data: profile } = await supabase
    .from("profiles")
    .select("is_admin")
    .eq("id", user.id)
    .single();

  if (!profile?.is_admin) return NextResponse.json({ error: "Forbidden" }, { status: 403 });

  const { event_id, duration_hours = 1 } = await req.json();
  const event = LIVE_EVENTS.find(e => e.id === event_id);
  if (!event) return NextResponse.json({ error: "Unknown event" }, { status: 400 });

  const endsAt = new Date(Date.now() + duration_hours * 3600 * 1000).toISOString();

  const { error } = await supabase.from("active_events").upsert({
    event_id,
    name: event.name,
    description: event.description,
    multiplier: event.multiplier,
    started_at: new Date().toISOString(),
    ends_at: endsAt,
  }, { onConflict: "event_id" });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ success: true, ends_at: endsAt });
}
