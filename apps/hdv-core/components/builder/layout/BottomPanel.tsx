import { useState, useCallback, useRef } from 'react';
import { useTerminalStore } from '@/lib/builder/store/terminalStore';
import { Terminal } from '@/components/builder/terminal/Terminal';
import { ProblemsPanel } from '@/components/builder/panel/ProblemsPanel';
import { OutputPanel } from '@/components/builder/panel/OutputPanel';
import { DebugConsolePanel } from '@/components/builder/panel/DebugConsolePanel';
import { TerminalIcon, ProblemsIcon, OutputIcon, DebugConsoleIcon } from '@/components/builder/icons';

type PanelTab = 'terminal' | 'problems' | 'output' | 'debugConsole';

const PANEL_TABS: { id: PanelTab; icon: React.FC<{ size?: number }>; label: string }[] = [
  { id: 'terminal', icon: TerminalIcon, label: 'TERMINAL' },
  { id: 'problems', icon: ProblemsIcon, label: 'PROBLEMS' },
  { id: 'output', icon: OutputIcon, label: 'OUTPUT' },
  { id: 'debugConsole', icon: DebugConsoleIcon, label: 'DEBUG CONSOLE' },
];

export function BottomPanel() {
  const { activePanelTab, setActivePanelTab, showPanel } = useTerminalStore();
  const [isResizing, setIsResizing] = useState(false);
  const [height, setHeight] = useState(200);
  const panelRef = useRef<HTMLDivElement>(null);

  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    setIsResizing(true);
    const startY = e.clientY;
    const startHeight = height;

    const handleMouseMove = (moveEvent: MouseEvent) => {
      const newHeight = startHeight - (moveEvent.clientY - startY);
      setHeight(newHeight);
    };

    const handleMouseUp = () => {
      setIsResizing(false);
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
    };

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);
  }, [height]);

  if (!showPanel) return null;

  return (
    <div
      ref={panelRef}
      style={{
        height,
        backgroundColor: 'var(--vscode-panel-bg)',
        display: 'flex',
        flexDirection: 'column',
        flexShrink: 0,
        position: 'relative',
        borderTop: '1px solid var(--vscode-panel-border)',
      }}
    >
      {/* Resize sash */}
      <div
        onMouseDown={handleMouseDown}
        style={{
          position: 'absolute',
          top: -3,
          left: 0,
          right: 0,
          height: 5,
          cursor: 'row-resize',
          zIndex: 10,
          backgroundColor: isResizing ? 'var(--vscode-sash-hover)' : 'transparent',
        }}
      />

      {/* Panel tab bar */}
      <div
        style={{
          height: 35,
          display: 'flex',
          alignItems: 'center',
          paddingLeft: 12,
          gap: 0,
          userSelect: 'none',
          borderBottom: '1px solid var(--vscode-panel-border)',
          flexShrink: 0,
        }}
      >
        {PANEL_TABS.map(({ id, icon: Icon, label }) => (
          <button
            key={id}
            onClick={() => setActivePanelTab(id)}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 4,
              height: 35,
              padding: '0 12px',
              background: 'transparent',
              border: 'none',
              borderBottom: activePanelTab === id ? '1px solid var(--vscode-focusBorder)' : '1px solid transparent',
              marginBottom: -1,
              color: activePanelTab === id ? 'var(--vscode-fg)' : 'var(--vscode-fg)',
              opacity: activePanelTab === id ? 1 : 0.6,
              cursor: 'pointer',
              fontSize: 11,
              fontWeight: 700,
              letterSpacing: 0.5,
              fontFamily: 'inherit',
            }}
          >
            <Icon size={14} />
            {label}
          </button>
        ))}
      </div>

      {/* Panel content */}
      <div style={{ flex: 1, overflow: 'hidden' }}>
        {activePanelTab === 'terminal' && <Terminal />}
        {activePanelTab === 'problems' && <ProblemsPanel />}
        {activePanelTab === 'output' && <OutputPanel />}
        {activePanelTab === 'debugConsole' && <DebugConsolePanel />}
      </div>
    </div>
  );
}
