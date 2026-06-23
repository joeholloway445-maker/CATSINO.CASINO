import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { data: tournaments } = await supabase
    .from("tournaments")
    .select("*")
    .order("starts_at", { ascending: false })
    .limit(20);

  const { data: entries } = await supabase
    .from("tournament_entries")
    .select("tournament_id, score, rank")
    .eq("user_id", user.id);

  return NextResponse.json({ tournaments: tournaments ?? [], my_entries: entries ?? [] });
}

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { tournament_id, action } = await req.json();
  if (!tournament_id || !action) return NextResponse.json({ error: "Missing fields" }, { status: 400 });

  if (action === "enter") {
    const { data, error } = await supabase.rpc("enter_tournament", { p_tournament_id: tournament_id });
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json(data);
  }

  return NextResponse.json({ error: "Unknown action" }, { status: 400 });
}
