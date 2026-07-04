import { NextResponse } from "next/server";
import { createAdminClient } from "@/lib/supabase/admin";

export const runtime = "nodejs";

export async function GET(req: Request) {
  const url = new URL(req.url);
  const tenantId = url.searchParams.get("tenant_id");

  const supabase = createAdminClient();
  let query = supabase.from("persona_ledger").select("module, cost_usd");
  if (tenantId) query = query.eq("tenant_id", tenantId);

  const { data, error } = await query;
  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  const byModule: Record<string, number> = {};
  let total = 0;
  for (const row of data ?? []) {
    const cost = Number(row.cost_usd) || 0;
    byModule[row.module] = (byModule[row.module] ?? 0) + cost;
    total += cost;
  }

  return NextResponse.json({
    executions: data?.length ?? 0,
    total_spend_usd: Number(total.toFixed(6)),
    by_module: Object.fromEntries(Object.entries(byModule).map(([k, v]) => [k, Number(v.toFixed(6))])),
  });
}
