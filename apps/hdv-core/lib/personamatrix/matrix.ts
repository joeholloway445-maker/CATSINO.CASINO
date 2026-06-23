// PersonaMatrix — Apex orchestration layer.
// Holds the registry of 4096 base identities x variants = 20,480 capacity,
// but holds them as DATA ONLY. Nothing runs until requested. Every request
// is spawn -> execute -> terminate, and the cost lands in the ledger.
import matrixConfig from "./config/matrix.json";
import { Persona } from "./persona";
import type { LedgerEntry, MatrixConfig, PersonaModule, PersonaTask, RequestResult } from "./types";

const cfg = matrixConfig as unknown as MatrixConfig;

let nextId = 0;

function costFor(role: string): number {
  return cfg.cost_model.role_overrides[role] ?? cfg.cost_model.default_cost_per_minute;
}

function mint(module: PersonaModule, role: string): Persona {
  const id = nextId % cfg.matrix.total_capacity;
  nextId += 1;
  return new Persona(id, module, role, costFor(role));
}

/** Spawn a persona, run one task, kill it, return the result + cost. Caller persists the ledger entry. */
export function request(module: PersonaModule, role: string, task: PersonaTask): RequestResult {
  const moduleCfg = cfg.modules[module];
  if (!moduleCfg) throw new Error(`Unknown module: ${module}`);
  if (!moduleCfg.roles.includes(role)) throw new Error(`Role '${role}' not allocated to ${module}`);

  const p = mint(module, role).spawn();
  const result = p.execute(task);
  const cost_usd = p.terminate();

  return { result: { ...result, persona_uid: p.uid }, cost_usd };
}

export function requestBatch(module: PersonaModule, role: string, tasks: PersonaTask[]): RequestResult[] {
  return tasks.map((t) => request(module, role, t));
}

export function buildLedgerEntry(
  module: PersonaModule,
  role: string,
  personaId: number,
  personaUid: string,
  costUsd: number,
  tenantId?: string | null
): LedgerEntry {
  return {
    ts: Date.now() / 1000,
    module,
    role,
    persona_id: personaId,
    persona_uid: personaUid,
    cost_usd: costUsd,
    tenant_id: tenantId ?? null,
  };
}

export function getMatrixConfig(): MatrixConfig {
  return cfg;
}
