import { type OutputLine } from '@/lib/builder/store/terminalStore';
import { useEffect, useRef } from 'react';

const LINE_COLORS: Record<string, string> = {
  prompt: 'var(--vscode-fg)',
  output: 'var(--vscode-fg)',
  error: '#f48771',
  success: '#89d185',
  info: '#75beff',
  'claude-input': '#75beff',
  'claude-output': 'var(--vscode-fg)',
  'claude-tool': '#ce9178',
};

export function TerminalOutput({ lines }: { lines: OutputLine[] }) {
  const bottomRef = useRef<HTMLDivElement>(null);
  useEffect(() => { bottomRef.current?.scrollIntoView({ behavior: 'auto' }); }, [lines]);
  return (
    <div style={{ flex: 1, overflowY: 'auto', padding: '4px 8px', fontFamily: '"Cascadia Code", "SF Mono", Menlo, Consolas, monospace', fontSize: 13, lineHeight: '19px' }}>
      {lines.map((line, i) => {
        const isToolCall = line.text.startsWith('\u25CF');
        const color = isToolCall ? '#4ec9b0' : (LINE_COLORS[line.type] || 'var(--vscode-fg)');
        return (
          <div key={i} style={{ color, whiteSpace: 'pre-wrap', wordBreak: 'break-word' }}>
            {line.text}
          </div>
        );
      })}
      <div ref={bottomRef} />
    </div>
  );
}
