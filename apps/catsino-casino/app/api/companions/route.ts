import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { data, error } = await supabase
    .from("companion_inventory")
    .select("*")
    .eq("user_id", user.id)
    .order("acquired_at", { ascending: false });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ companions: data ?? [] });
}

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { companion_id, action } = await req.json();
  if (!companion_id || !action) return NextResponse.json({ error: "Missing fields" }, { status: 400 });

  if (action === "equip") {
    const { error } = await supabase
      .from("companion_inventory")
      .update({ equipped: true })
      .eq("user_id", user.id)
      .eq("companion_id", companion_id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true });
  }

  if (action === "unequip") {
    const { error } = await supabase
      .from("companion_inventory")
      .update({ equipped: false })
      .eq("user_id", user.id)
      .eq("companion_id", companion_id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true });
  }

  return NextResponse.json({ error: "Unknown action" }, { status: 400 });
}
