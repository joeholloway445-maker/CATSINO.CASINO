export type PersonaModule = "dream" | "hope" | "no_one" | "vision" | "apex";

export type PersonaRole =
  | "commenter"
  | "hype_agent"
  | "filter_director"
  | "co_streamer"
  | "content_gen"
  | "clip_editor"
  | "caption_writer"
  | "validator"
  | "auditor"
  | "rate_limiter"
  | "workflow_agent"
  | "tenant_admin"
  | "router"
  | "billing"
  | "load_balancer";

export interface ModuleConfig {
  purpose: string;
  persona_allocation: number;
  roles: string[];
  priority: number;
  status: "MVP" | "planned";
}

export interface MatrixConfig {
  matrix: {
    name: string;
    version: string;
    base_entity_count: number;
    variants_per_entity: number;
    total_capacity: number;
    lifecycle_policy: string;
    comment: string;
  };
  modules: Record<PersonaModule, ModuleConfig>;
  cost_model: {
    currency: string;
    default_cost_per_minute: number;
    role_overrides: Record<string, number>;
    kill_after_seconds_idle: number;
  };
}

export interface PersonaTask {
  [key: string]: unknown;
}

export interface PersonaResult {
  persona: number;
  type?: string;
  [key: string]: unknown;
}

export interface LedgerEntry {
  ts: number;
  module: PersonaModule;
  role: string;
  persona_id: number;
  persona_uid: string;
  cost_usd: number;
  tenant_id?: string | null;
}

export interface RequestPayload {
  module: PersonaModule;
  role: string;
  task: PersonaTask;
  tenant_id?: string;
}

export interface RequestResult {
  result: PersonaResult;
  cost_usd: number;
}
