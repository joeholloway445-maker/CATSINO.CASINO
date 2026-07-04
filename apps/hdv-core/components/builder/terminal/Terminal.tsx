import { useCallback, useRef } from 'react';
import { useTerminalStore, type OutputLine } from '@/lib/builder/store/terminalStore';
import { processCommand } from './shellCommands';
import { TerminalOutput } from './TerminalOutput';
import { TerminalInput } from './TerminalInput';
import { streamClaudeReply } from './streamClaude';

const CLAUDE_BANNER =
  '* Claude REPL — PersonaMatrix backbone\n' +
  '  \n' +
  '  Each message is sent to POST /api/personamatrix/request\n' +
  '  (module "apex", role "commenter") and the reply below is a real\n' +
  '  persona response, spawned/executed/terminated server-side.\n' +
  '  Type a message or use /help for available commands.\n';

export function Terminal() {
  const store = useTerminalStore();
  const { terminals, activeTerminalId } = store;
  const active = terminals.find((t) => t.id === activeTerminalId) || terminals[0];
  const streamAbortRef = useRef(false);

  const handleCommand = useCallback(
    (cmd: string) => {
      if (!active) return;
      const promptText =
        active.mode === 'claude'
          ? `> ${cmd}`
          : `user@vscode:${active.cwd}$ ${cmd}`;
      store.addOutput(active.id, { type: 'prompt', text: promptText });
      store.addHistory(active.id, cmd);

      const result = processCommand(cmd, active.cwd, active.mode);

      if (result.clear) {
        store.clearOutput(active.id);
        return;
      }

      if (result.enterClaude) {
        store.setMode(active.id, 'claude');
        store.addOutput(active.id, { type: 'output', text: CLAUDE_BANNER });
        return;
      }

      if (result.exitClaude) {
        store.setMode(active.id, 'shell');
        store.addOutput(active.id, { type: 'output', text: '[exited Claude REPL]' });
        return;
      }

      if (result.streamReply) {
        streamAbortRef.current = false;
        streamClaudeReply(store, active.id, result.streamReply, () => streamAbortRef.current);
        return;
      }

      if (result.output) {
        const lineType: OutputLine['type'] = result.error
          ? 'error'
          : result.success
            ? 'success'
            : 'output';
        store.addOutput(active.id, {
          type: lineType,
          text: result.output,
        });
      }

      if (result.newCwd !== active.cwd) {
        store.setCwd(active.id, result.newCwd);
      }
    },
    [active?.id, active?.cwd, active?.mode, store]
  );

  const handleInterrupt = useCallback(() => {
    if (!active) return;
    if (active.mode === 'claude') {
      streamAbortRef.current = true;
      store.addOutput(active.id, { type: 'info', text: '^C (interrupted)' });
    } else {
      store.addOutput(active.id, { type: 'info', text: '^C' });
    }
  }, [active, store]);

  if (!active)
    return (
      <div style={{ padding: 8, opacity: 0.5 }}>No terminal</div>
    );

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* Tab bar */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          borderBottom: '1px solid var(--vscode-panel-border)',
          padding: '0 4px',
          flexShrink: 0,
        }}
      >
        {terminals.map((t) => (
          <button
            key={t.id}
            onClick={() => store.setActiveTerminal(t.id)}
            style={{
              padding: '4px 12px',
              fontSize: 12,
              background: 'transparent',
              border: 'none',
              borderBottom:
                t.id === activeTerminalId
                  ? '1px solid #fff'
                  : '1px solid transparent',
              color: 'var(--vscode-fg)',
              opacity: t.id === activeTerminalId ? 1 : 0.6,
              cursor: 'pointer',
              display: 'flex',
              alignItems: 'center',
              gap: 4,
            }}
          >
            {t.name}
            <span
              onClick={(e) => {
                e.stopPropagation();
                store.closeTerminal(t.id);
              }}
              style={{
                marginLeft: 4,
                cursor: 'pointer',
                opacity: 0.5,
                fontSize: 10,
              }}
            >
              {'\u00D7'}
            </span>
          </button>
        ))}
        <button
          onClick={() => {
            let maxNum = 1;
            for (const t of terminals) {
              const m = t.name.match(/^bash-(\d+)$/);
              if (m) maxNum = Math.max(maxNum, parseInt(m[1], 10));
              if (t.name === 'bash') maxNum = Math.max(maxNum, 1);
            }
            store.createTerminal(`bash-${maxNum + 1}`);
          }}
          style={{
            padding: '4px 8px',
            fontSize: 14,
            background: 'transparent',
            border: 'none',
            color: 'var(--vscode-fg)',
            cursor: 'pointer',
            opacity: 0.6,
          }}
        >
          +
        </button>
      </div>
      <TerminalOutput lines={active.output} />
      <TerminalInput
        onSubmit={handleCommand}
        onInterrupt={handleInterrupt}
        history={active.history}
        cwd={active.cwd}
        mode={active.mode}
      />
    </div>
  );
}
