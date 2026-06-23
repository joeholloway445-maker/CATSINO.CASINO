const PROBLEMS = [
  { severity: 'warning', file: 'src/App.tsx', line: 15, col: 1, message: "'useEffect' is defined but never used" },
  { severity: 'warning', file: 'src/utils/helpers.ts', line: 8, col: 10, message: "Function 'debounce' has a complexity of 12" },
];

export function ProblemsPanel() {
  return (
    <div style={{ padding: '8px 16px', fontSize: 13, overflowY: 'auto', height: '100%' }}>
      {PROBLEMS.map((p, i) => (
        <div key={i} style={{ display: 'flex', alignItems: 'flex-start', gap: 8, padding: '4px 0', cursor: 'pointer' }}>
          <span style={{ color: '#cca700' }}>{'\u26a0'}</span>
          <div>
            <div style={{ color: 'var(--vscode-fg)' }}>{p.message}</div>
            <div style={{ fontSize: 12, opacity: 0.6 }}>{p.file} [{p.line},{p.col}]</div>
          </div>
        </div>
      ))}
    </div>
  );
}
