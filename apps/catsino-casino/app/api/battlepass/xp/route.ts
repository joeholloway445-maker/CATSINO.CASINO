import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { xp_amount } = await req.json();
  if (!xp_amount || xp_amount <= 0) return NextResponse.json({ error: "Invalid xp_amount" }, { status: 400 });

  const { data, error } = await supabase.rpc("add_profile_xp", { p_amount: xp_amount });
  if (error) return NextResponse.json({ error: error.message }, { status: 400 });

  return NextResponse.json({ success: true, total_xp: data?.total_xp ?? 0, level: data?.level ?? 1 });
}
