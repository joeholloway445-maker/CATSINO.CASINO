import type { TerminalState } from '@/lib/builder/store/terminalStore';

type Store = TerminalState;

// The Claude REPL in this builder used to fake "Claude" output by chopping a
// static canned string into tokens via setInterval. That's gone: this now
// makes a real call into this repo's PersonaMatrix backend
// (POST /api/personamatrix/request, module "apex", role "commenter") and
// types out the actual reply text it gets back. The content originates from
// a real persona spawned/executed server-side — only the token-by-token
// reveal below is a cosmetic streaming effect.

interface PersonaMatrixResult {
  persona: number;
  type?: string;
  text?: string;
  [key: string]: unknown;
}

interface PersonaMatrixResponse {
  result: PersonaMatrixResult;
  cost_usd: number;
}

const TOKEN_INTERVAL_MS = 30;

export function streamClaudeReply(
  store: Store,
  terminalId: string,
  prompt: string,
  isAborted: () => boolean
) {
  let aborted = false;

  const typeOut = (text: string) => {
    const tokens = text.split(/(\s+|[\n\r])/g).filter(Boolean);
    let index = 0;
    const interval = setInterval(() => {
      if (aborted || isAborted()) {
        clearInterval(interval);
        return;
      }
      if (index >= tokens.length) {
        clearInterval(interval);
        return;
      }
      store.appendOutput(terminalId, tokens[index]);
      index++;
    }, TOKEN_INTERVAL_MS);
  };

  void (async () => {
    try {
      const res = await fetch('/api/personamatrix/request', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          module: 'apex',
          role: 'commenter',
          task: { context: prompt },
        }),
      });

      if (aborted || isAborted()) return;

      if (!res.ok) {
        store.appendOutput(
          terminalId,
          `\n● PersonaMatrix request failed (HTTP ${res.status})\n`
        );
        return;
      }

      const data = (await res.json()) as PersonaMatrixResponse;
      const replyText = data.result.text ?? '(no response)';
      const costSuffix = ` (cost=$${data.cost_usd.toFixed(8)})`;

      typeOut(`persona_${data.result.persona}: ${replyText}${costSuffix}\n`);
    } catch {
      if (aborted || isAborted()) return;
      store.appendOutput(
        terminalId,
        '\n● [PersonaMatrix request error — could not reach backend]\n'
      );
    }
  })();

  return () => {
    aborted = true;
  };
}
