import { type NextRequest, NextResponse } from "next/server";
import { createAdminClient } from "@/lib/supabase/admin";

export const runtime = "nodejs";

// Public read — powers the Dex (SEO entity pages). Writes happen only via the
// Entity Roster import script, never from a client.
export async function GET(req: NextRequest) {
  const url = new URL(req.url);
  const mod = url.searchParams.get("module");
  const id = url.searchParams.get("id");

  const supabase = createAdminClient();
  let query = supabase.from("personas").select("*").order("id", { ascending: true });
  if (mod) query = query.eq("module", mod);
  if (id) query = query.eq("id", Number(id));

  const { data, error } = await query;
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ personas: data });
}
