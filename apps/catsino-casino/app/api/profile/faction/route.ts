import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

const VALID_FACTIONS = ["SovereignCrown", "WildlandsAscendant", "VeiledCurrent", "Factionless"];

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { faction } = await req.json();
  if (!VALID_FACTIONS.includes(faction))
    return NextResponse.json({ error: "Invalid faction" }, { status: 400 });

  const { error } = await supabase
    .from("profiles")
    .update({ faction })
    .eq("id", user.id);

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ success: true, faction });
}

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { data } = await supabase.from("profiles").select("faction").eq("id", user.id).single();
  return NextResponse.json({ faction: data?.faction ?? "Factionless" });
}
