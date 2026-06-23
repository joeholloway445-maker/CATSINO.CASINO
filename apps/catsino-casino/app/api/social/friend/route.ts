import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(req: Request) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { username } = await req.json();
  if (!username?.trim()) return NextResponse.json({ error: "Username required" }, { status: 400 });

  const { data: target } = await supabase
    .from("profiles")
    .select("id, username")
    .eq("username", username.trim())
    .single();

  if (!target) return NextResponse.json({ error: "User not found" }, { status: 404 });
  if (target.id === user.id) return NextResponse.json({ error: "Cannot add yourself" }, { status: 400 });

  const { error } = await supabase.from("friends").upsert(
    { user_id: user.id, friend_id: target.id },
    { onConflict: "user_id,friend_id" }
  );

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ success: true, friend: target.username });
}
