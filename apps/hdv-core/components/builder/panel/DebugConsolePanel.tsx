import { useState } from 'react';

const BLOCKED = /fetch|location|document\.cookie|window\.|eval|Function\s*\(/;

export function DebugConsolePanel() {
  const [history, setHistory] = useState<{ input: string; result: string; error?: boolean }[]>([]);
  const [input, setInput] = useState('');

  const handleSubmit = () => {
    if (!input.trim()) return;
    const expr = input.trim();
    if (BLOCKED.test(expr)) {
      setHistory([...history, { input: expr, result: '[blocked for security]', error: true }]);
      setInput('');
      return;
    }
    try {
      const result = eval(`(() => { const fetch = undefined; const location = undefined; return (${expr}); })()`);
      setHistory([...history, { input: expr, result: String(result) }]);
    } catch (e) {
      setHistory([...history, { input: expr, result: String(e), error: true }]);
    }
    setInput('');
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', fontSize: 13, fontFamily: '"Cascadia Code", "SF Mono", Menlo, Consolas, monospace' }}>
      <div style={{ flex: 1, overflowY: 'auto', padding: '8px 16px' }}>
        {history.map((h, i) => (
          <div key={i}>
            <div style={{ color: 'var(--vscode-fg)' }}>{'>'} {h.input}</div>
            <div style={{ color: h.error ? '#f48771' : 'var(--vscode-fg)' }}>{h.result}</div>
          </div>
        ))}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', padding: '4px 16px', borderTop: '1px solid var(--vscode-panel-border)', gap: 4 }}>
        <span style={{ color: 'var(--vscode-success)' }}>{'>'}</span>
        <input value={input} onChange={e => setInput(e.target.value)} onKeyDown={e => e.key === 'Enter' && handleSubmit()}
          style={{ flex: 1, background: 'transparent', border: 'none', outline: 'none', color: 'var(--vscode-fg)', fontFamily: 'inherit', fontSize: 13 }}
          spellCheck={false} autoComplete="off" />
      </div>
    </div>
  );
}
