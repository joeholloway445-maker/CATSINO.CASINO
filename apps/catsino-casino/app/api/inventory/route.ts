import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

export async function GET() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { data, error } = await supabase
    .from("inventory")
    .select("*")
    .eq("user_id", user.id)
    .order("acquired_at", { ascending: false });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ items: data ?? [] });
}

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { item_id, action } = await req.json();
  if (!item_id || !action) return NextResponse.json({ error: "Missing fields" }, { status: 400 });

  if (action === "equip" || action === "unequip") {
    const { error } = await supabase
      .from("inventory")
      .update({ equipped: action === "equip" })
      .eq("user_id", user.id)
      .eq("item_id", item_id);
    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true });
  }

  if (action === "use") {
    const { data: item } = await supabase
      .from("inventory")
      .select("*")
      .eq("user_id", user.id)
      .eq("item_id", item_id)
      .single();

    if (!item || item.quantity < 1) return NextResponse.json({ error: "Item not available" }, { status: 400 });

    if (item.quantity === 1) {
      await supabase.from("inventory").delete().eq("user_id", user.id).eq("item_id", item_id);
    } else {
      await supabase.from("inventory").update({ quantity: item.quantity - 1 }).eq("user_id", user.id).eq("item_id", item_id);
    }

    return NextResponse.json({ success: true, used: item_id });
  }

  return NextResponse.json({ error: "Unknown action" }, { status: 400 });
}
