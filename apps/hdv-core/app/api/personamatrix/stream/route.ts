// Server-Sent Events stream of live persona chat for the Dream studio.
//
// Instead of the studio firing one POST /request per chat line, it opens a
// single GET /stream connection and the server spawns commenter (and the odd
// filter_director) personas server-side through the SAME Apex backbone, pushing
// each result down as an SSE `message`. This is the "route to automation": one
// connection, the backbone decides who speaks, every spawn lands in the ledger.
//
//   GET /api/personamatrix/stream?energy=0.7&module=dream
//     → event stream of { persona, type, text, cost_usd, chain? }
//
// `energy` (0..1) scales the chat burst rate, mirroring the slider in the deck.

import { type NextRequest } from "next/server";
import { request as matrixRequest } from "@/lib/personamatrix/matrix";
import { createAdminClient } from "@/lib/supabase/admin";
import type { PersonaModule } from "@/lib/personamatrix/types";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

const VALID: PersonaModule[] = ["dream", "hope", "no_one", "vision", "apex"];

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const mod = (searchParams.get("module") ?? "dream") as PersonaModule;
  if (!VALID.includes(mod)) {
    return new Response(`data: ${JSON.stringify({ error: "bad module" })}\n\n`, {
      status: 400,
      headers: { "content-type": "text/event-stream" },
    });
  }
  let energy = Number(searchParams.get("energy") ?? "0.5");
  if (!Number.isFinite(energy)) energy = 0.5;
  energy = Math.min(1, Math.max(0, energy));

  const enc = new TextEncoder();
  let closed = false;

  const stream = new ReadableStream({
    start(controller) {
      const send = (obj: unknown) => {
        if (closed) return;
        controller.enqueue(enc.encode(`data: ${JSON.stringify(obj)}\n\n`));
      };

      const ledger: Array<Record<string, unknown>> = [];
      const flushLedger = async () => {
        if (!ledger.length) return;
        const batch = ledger.splice(0, ledger.length);
        try {
          await createAdminClient().from("persona_ledger").insert(batch);
        } catch {
          /* ledger writes never block the live stream */
        }
      };

      const beat = () => {
        if (closed) return;
        // Every few beats a filter_director re-reads energy and picks a chain.
        if (Math.random() < 0.25) {
          const { result, cost_usd } = matrixRequest(mod, "filter_director", { energy });
          send({ ...result, cost_usd, kind: "director" });
          ledger.push(ledgerRow(mod, "filter_director", result, cost_usd));
        }
        // A burst of commenters scaled by energy.
        const burst = 1 + Math.floor(Math.random() * (1 + energy * 4));
        for (let i = 0; i < burst; i++) {
          const { result, cost_usd } = matrixRequest(mod, "commenter", { context: "the proceedings" });
          send({ ...result, cost_usd, kind: "chat" });
          ledger.push(ledgerRow(mod, "commenter", result, cost_usd));
        }
        void flushLedger();
        // Faster cadence at higher energy.
        timer = setTimeout(beat, 1200 - energy * 800);
      };

      send({ kind: "hello", module: mod, energy });
      let timer = setTimeout(beat, 200);

      const keepAlive = setInterval(() => {
        if (!closed) controller.enqueue(enc.encode(": ping\n\n"));
      }, 15000);

      const close = () => {
        if (closed) return;
        closed = true;
        clearTimeout(timer);
        clearInterval(keepAlive);
        void flushLedger();
        try { controller.close(); } catch { /* already closed */ }
      };
      req.signal.addEventListener("abort", close);
    },
    cancel() {
      closed = true;
    },
  });

  return new Response(stream, {
    headers: {
      "content-type": "text/event-stream",
      "cache-control": "no-cache, no-transform",
      connection: "keep-alive",
    },
  });
}

function ledgerRow(
  module: string,
  role: string,
  result: Record<string, unknown>,
  cost_usd: number,
) {
  // Columns mirror supabase/migrations/002_personamatrix.sql exactly. The
  // stream stays anonymous-by-default (tenant_id null); the per-tenant billed
  // path is POST /request, which resolves the X-Api-Key to a tenant.
  return {
    module,
    role,
    persona_id: (result.persona as number) ?? 0,
    persona_uid: (result.persona_uid as string) ?? "unknown",
    cost_usd,
    tenant_id: null as string | null,
    task: {},
    result,
  };
}
