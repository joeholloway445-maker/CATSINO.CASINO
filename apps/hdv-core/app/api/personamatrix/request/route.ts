import { type NextRequest, NextResponse } from "next/server";
import { request as matrixRequest } from "@/lib/personamatrix/matrix";
import { createAdminClient } from "@/lib/supabase/admin";
import type { PersonaModule, RequestPayload } from "@/lib/personamatrix/types";

export const runtime = "nodejs";

const VALID_MODULES: PersonaModule[] = ["dream", "hope", "no_one", "vision", "apex"];

async function resolveTenant(apiKey: string | null) {
  if (!apiKey) return null;
  const supabase = createAdminClient();
  const { data } = await supabase
    .from("tenants")
    .select("id, active")
    .eq("api_key", apiKey)
    .maybeSingle();
  if (!data || !data.active) return null;
  return data.id as string;
}

export async function POST(req: NextRequest) {
  let payload: RequestPayload;
  try {
    payload = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const { module, role, task } = payload;
  if (!module || !VALID_MODULES.includes(module)) {
    return NextResponse.json({ error: `module must be one of ${VALID_MODULES.join(", ")}` }, { status: 400 });
  }
  if (!role) {
    return NextResponse.json({ error: "role is required" }, { status: 400 });
  }

  // API-key auth is optional for now (Apex/Dream can run unauthenticated locally);
  // once a tenant row exists for a key, requests bearing it are billed to that tenant.
  const apiKey = req.headers.get("x-api-key");
  const tenantId = await resolveTenant(apiKey);

  let outcome: ReturnType<typeof matrixRequest>;
  try {
    outcome = matrixRequest(module, role, task ?? {});
  } catch (err) {
    return NextResponse.json({ error: err instanceof Error ? err.message : "request failed" }, { status: 400 });
  }

  const { result, cost_usd } = outcome;

  try {
    const supabase = createAdminClient();
    await supabase.from("persona_ledger").insert({
      module,
      role,
      persona_id: result.persona as number,
      persona_uid: (result.persona_uid as string) ?? "unknown",
      cost_usd,
      tenant_id: tenantId,
      task: task ?? {},
      result,
    });
  } catch (err) {
    // Ledger write failures must never block the response — the work already happened
    // and the persona is already dead; we log and move on rather than double-charging on retry.
    console.error("PersonaMatrix ledger write failed:", err);
  }

  return NextResponse.json({ result, cost_usd });
}
