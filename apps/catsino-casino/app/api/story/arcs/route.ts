import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { data: arcs, error: arcsError } = await supabase
    .from("story_arcs")
    .select("id, slug, title, description, status, closes_at, resolved_at, winning_choice_id")
    .order("created_at", { ascending: false });
  if (arcsError) return NextResponse.json({ error: arcsError.message }, { status: 500 });

  const arcIds = (arcs ?? []).map((a) => a.id);
  const { data: choices } = await supabase
    .from("story_choices")
    .select("id, arc_id, choice_key, label, description")
    .in("arc_id", arcIds.length ? arcIds : ["00000000-0000-0000-0000-000000000000"]);

  const { data: wagers } = await supabase
    .from("story_wagers")
    .select("arc_id, choice_id, faction, currency, amount")
    .in("arc_id", arcIds.length ? arcIds : ["00000000-0000-0000-0000-000000000000"]);

  const { data: myWagers } = await supabase
    .from("story_wagers")
    .select("arc_id, choice_id, currency, amount, payout")
    .eq("user_id", user.id);

  const tallies: Record<string, { byChoice: Record<string, Record<string, number>>; byFaction: Record<string, Record<string, number>> }> = {};
  for (const w of wagers ?? []) {
    const t = tallies[w.arc_id] ?? { byChoice: {}, byFaction: {} };
    t.byChoice[w.choice_id] = t.byChoice[w.choice_id] ?? {};
    t.byChoice[w.choice_id][w.currency] = (t.byChoice[w.choice_id][w.currency] ?? 0) + w.amount;
    t.byFaction[w.faction] = t.byFaction[w.faction] ?? {};
    t.byFaction[w.faction][w.currency] = (t.byFaction[w.faction][w.currency] ?? 0) + w.amount;
    tallies[w.arc_id] = t;
  }

  const result = (arcs ?? []).map((arc) => ({
    ...arc,
    choices: (choices ?? []).filter((c) => c.arc_id === arc.id),
    tally: tallies[arc.id] ?? { byChoice: {}, byFaction: {} },
    myWagers: (myWagers ?? []).filter((w) => w.arc_id === arc.id),
  }));

  return NextResponse.json({ arcs: result });
}
