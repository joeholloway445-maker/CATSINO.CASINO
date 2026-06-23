import { useState } from 'react';

const CHANNELS: Record<string, string[]> = {
  Vite: ['[vite] connected.', '[vite] page reload src/App.tsx (12:45:30)', '[vite] hmr update /src/main.tsx (12:46:15)', '[vite] hmr update /src/index.css (12:47:02)', '[vite] connected.'],
  TypeScript: ['Starting compilation in watch mode...', 'Found 0 errors. Watching for file changes.'],
  ESLint: ['\u2713 No ESLint warnings or errors found', 'Checking src/App.tsx...', '\u2713 All files pass linting.'],
};

export function OutputPanel() {
  const [channel, setChannel] = useState('Vite');
  return (
    <div style={{ padding: '8px 16px', fontSize: 13, height: '100%', overflowY: 'auto', fontFamily: '"Cascadia Code", "SF Mono", Menlo, Consolas, monospace' }}>
      <select value={channel} onChange={e => setChannel(e.target.value)} style={{ background: 'var(--vscode-input-bg)', color: 'var(--vscode-fg)', border: '1px solid var(--vscode-border)', padding: '2px 8px', fontSize: 12, marginBottom: 8 }}>
        {Object.keys(CHANNELS).map(c => <option key={c} value={c}>{c}</option>)}
      </select>
      {CHANNELS[channel].map((line, i) => <div key={i} style={{ padding: '1px 0' }}>{line}</div>)}
    </div>
  );
}
