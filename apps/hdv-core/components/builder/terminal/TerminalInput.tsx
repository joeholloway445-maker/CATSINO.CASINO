import { useState, useRef, useEffect } from 'react';

interface Props {
  onSubmit: (cmd: string) => void;
  onInterrupt: () => void;
  history: string[];
  cwd: string;
  mode?: 'shell' | 'claude';
}

export function TerminalInput({ onSubmit, onInterrupt, history, cwd, mode = 'shell' }: Props) {
  const [value, setValue] = useState('');
  const [histIdx, setHistIdx] = useState(-1);
  const inputRef = useRef<HTMLInputElement>(null);

  const isClaude = mode === 'claude';
  const prompt = isClaude
    ? '>'
    : (cwd === '/home/user/workspace' ? '~/workspace' : cwd);

  useEffect(() => { inputRef.current?.focus(); }, []);

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      if (value.trim()) { onSubmit(value.trim()); setValue(''); setHistIdx(-1); }
    } else if (e.ctrlKey && e.key === 'c') {
      e.preventDefault();
      onInterrupt();
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      if (history.length === 0) return;
      const idx = histIdx === -1 ? history.length - 1 : Math.max(0, histIdx - 1);
      setHistIdx(idx);
      setValue(history[idx] || '');
    } else if (e.key === 'ArrowDown') {
      e.preventDefault();
      if (histIdx === -1) return;
      const idx = histIdx + 1;
      if (idx >= history.length) { setHistIdx(-1); setValue(''); }
      else { setHistIdx(idx); setValue(history[idx] || ''); }
    }
  };

  return (
    <div style={{ display: 'flex', alignItems: 'center', padding: '2px 8px', gap: 4, fontFamily: '"Cascadia Code", "SF Mono", Menlo, Consolas, monospace', fontSize: 13, borderTop: '1px solid var(--vscode-panel-border)' }}>
      <span style={{ color: isClaude ? '#75beff' : 'var(--vscode-success)', whiteSpace: 'nowrap', userSelect: 'none' }}>
        {isClaude ? '>' : `user@vscode:${prompt}$`}
      </span>
      <input
        ref={inputRef}
        type="text"
        value={value}
        onChange={e => setValue(e.target.value)}
        onKeyDown={handleKeyDown}
        spellCheck={false}
        autoComplete="off"
        style={{ flex: 1, background: 'transparent', border: 'none', outline: 'none', color: 'var(--vscode-fg)', fontFamily: 'inherit', fontSize: 13, padding: 0, margin: 0 }}
      />
    </div>
  );
}
