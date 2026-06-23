// PersonaMatrix Core — ephemeral persona lifecycle.
// Design rule: personas are NEVER long-running. spawn() -> execute() -> terminate()
// happens in one breath. Cost is tracked per execution so Apex can bill/budget.
import { randomUUID } from "crypto";
import type { PersonaModule, PersonaResult, PersonaTask } from "./types";

type RoleHandler = (p: Persona, task: PersonaTask) => PersonaResult;

const CHAT_LINES = [
  (id: number, ctx: string) => `NO WAY did that just happen on ${ctx}`,
  () => "chat is this real",
  (id: number) => `clip it. CLIP IT. #${id}`,
  () => "the filter just ate my whole screen lmaooo",
  () => "I've been here 4 hours send help",
  (id: number) => `persona_${id} has entered the proceedings`,
  () => "this is the squid game arc fr",
  () => "W stream W filter W everything",
];

function pick<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

function commenter(p: Persona, task: PersonaTask): PersonaResult {
  const ctx = (task.context as string) ?? "the stream";
  const line = pick(CHAT_LINES)(p.id, ctx);
  return { persona: p.id, type: "chat", text: line };
}

function hypeAgent(p: Persona): PersonaResult {
  const emotes = ["🔥", "💀", "👁️", "🎭", "⬛🔺⭕"];
  return { persona: p.id, type: "reaction", emote: pick(emotes), intensity: 1 + Math.floor(Math.random() * 10) };
}

function filterDirector(p: Persona, task: PersonaTask): PersonaResult {
  const energy = typeof task.energy === "number" ? task.energy : 0.5;
  let chain: string;
  if (energy > 0.8) chain = "full_breakdown";
  else if (energy > 0.5) chain = "scarecrow_proceedings";
  else chain = "squid_round";
  return { persona: p.id, type: "directive", trigger_chain: chain, energy };
}

function defaultHandler(p: Persona, task: PersonaTask): PersonaResult {
  return { persona: p.id, type: "noop", task };
}

const ROLE_HANDLERS: Record<string, RoleHandler> = {
  commenter,
  hype_agent: hypeAgent,
  filter_director: filterDirector,
};

export class Persona {
  id: number;
  uid: string;
  module: PersonaModule;
  role: string;
  costPerMin: number;
  state: "void" | "active" | "dead" = "void";
  private t0: number | null = null;

  constructor(id: number, module: PersonaModule, role: string, costPerMin: number) {
    this.id = id;
    this.uid = randomUUID().slice(0, 8);
    this.module = module;
    this.role = role;
    this.costPerMin = costPerMin;
  }

  spawn(): this {
    this.state = "active";
    this.t0 = Date.now();
    return this;
  }

  execute(task: PersonaTask): PersonaResult {
    if (this.state !== "active") {
      throw new Error(`Persona ${this.id} executed without spawn()`);
    }
    const handler = ROLE_HANDLERS[this.role] ?? defaultHandler;
    return handler(this, task);
  }

  /** Kill immediately. Returns cost of this execution in USD. */
  terminate(): number {
    const elapsedSec = (Date.now() - (this.t0 ?? Date.now())) / 1000;
    this.state = "dead";
    return Number(((elapsedSec * this.costPerMin) / 60).toFixed(8));
  }
}
