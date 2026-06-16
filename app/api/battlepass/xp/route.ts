import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { xp_amount } = await req.json();
  if (!xp_amount || xp_amount <= 0) return NextResponse.json({ error: "Invalid xp_amount" }, { status: 400 });

  const { error } = await supabase
    .from("profiles")
    .update({ total_xp: supabase.rpc("coalesce_add_xp", { xp: xp_amount }) })
    .eq("id", user.id);

  if (error) {
    // Fallback: direct update
    const { data: current } = await supabase.from("profiles").select("total_xp").eq("id", user.id).single();
    const new_xp = (current?.total_xp ?? 0) + xp_amount;
    await supabase.from("profiles").update({ total_xp: new_xp }).eq("id", user.id);
  }

  const { data: updated } = await supabase.from("profiles").select("total_xp, level").eq("id", user.id).single();
  return NextResponse.json({ success: true, total_xp: updated?.total_xp ?? 0, level: updated?.level ?? 1 });
}
