import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { data, error } = await supabase
    .from("mount_inventory")
    .select("*")
    .eq("user_id", user.id)
    .order("acquired_at", { ascending: false });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ mounts: data ?? [] });
}

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { mount_id, action } = await req.json();
  if (!mount_id || !action) return NextResponse.json({ error: "Missing fields" }, { status: 400 });

  if (action === "equip") {
    const { error } = await supabase
      .from("mount_inventory")
      .update({ equipped: true })
      .eq("user_id", user.id)
      .eq("mount_id", mount_id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true });
  }

  if (action === "unequip") {
    const { error } = await supabase
      .from("mount_inventory")
      .update({ equipped: false })
      .eq("user_id", user.id)
      .eq("mount_id", mount_id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true });
  }

  return NextResponse.json({ error: "Unknown action" }, { status: 400 });
}
