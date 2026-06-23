import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { xp } = await req.json();
  if (typeof xp !== "number" || xp <= 0)
    return NextResponse.json({ error: "Invalid XP amount" }, { status: 400 });

  const { data, error } = await supabase.rpc("add_profile_xp", { p_amount: xp });
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  return NextResponse.json({ success: true, ...(data ?? {}) });
}
