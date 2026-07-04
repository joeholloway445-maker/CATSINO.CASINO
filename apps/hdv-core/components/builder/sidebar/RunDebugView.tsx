import { useState } from 'react';
import { DebugIcon } from '@/components/builder/icons';
import { PlayCircleIcon, StopCircleIcon, ListTreeIcon } from './ExtensionIcons';
import { ChevronDownIcon, ChevronRightIcon } from '@/components/builder/icons';

interface LaunchConfig {
  id: string;
  name: string;
  type: string;
}

const launchConfigs: LaunchConfig[] = [
  { id: '1', name: 'Launch Chrome against localhost', type: 'chrome' },
  { id: '2', name: 'Launch Program (Node)', type: 'node' },
  { id: '3', name: 'Attach to Process', type: 'node' },
  { id: '4', name: 'Jest: Current File', type: 'node' },
];

interface Variable {
  name: string;
  value: string;
  type: string;
}

const mockVariables: Variable[] = [
  { name: 'count', value: '42', type: 'number' },
  { name: 'user', value: '{ name: "Jane", id: 1 }', type: 'object' },
  { name: 'isActive', value: 'true', type: 'boolean' },
  { name: 'items', value: '["a", "b", "c"]', type: 'array' },
];

interface CallStackFrame {
  name: string;
  file: string;
  line: number;
}

const mockCallStack: CallStackFrame[] = [
  { name: 'handleClick', file: 'src/components/Button.tsx', line: 24 },
  { name: 'onClick', file: 'src/App.tsx', line: 56 },
  { name: 'dispatchEvent', file: 'react-dom.development.js', line: 3271 },
];

interface Breakpoint {
  file: string;
  line: number;
  enabled: boolean;
}

const mockBreakpoints: Breakpoint[] = [
  { file: 'src/App.tsx', line: 15, enabled: true },
  { file: 'src/components/Header.tsx', line: 42, enabled: true },
  { file: 'src/utils/helpers.ts', line: 8, enabled: false },
];

export function RunDebugView() {
  const [selectedConfig, setSelectedConfig] = useState<LaunchConfig>(launchConfigs[0]);
  const [showDropdown, setShowDropdown] = useState(false);
  const [isRunning, setIsRunning] = useState(false);
  const [sections, setSections] = useState({
    variables: true,
    callstack: true,
    breakpoints: true,
  });

  const handleRun = () => {
    if (isRunning) {
      setIsRunning(false);
      window.dispatchEvent(new CustomEvent('vscode:stopDebug'));
    } else {
      setIsRunning(true);
      window.dispatchEvent(new CustomEvent('vscode:runDebug'));
    }
  };

  const toggleSection = (key: keyof typeof sections) => {
    setSections(prev => ({ ...prev, [key]: !prev[key] }));
  };

  return (
    <div className="flex flex-col h-full text-[var(--vscode-fg)]">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-2">
        <span className="text-xs font-bold tracking-wide opacity-80">RUN AND DEBUG</span>
      </div>

      {/* Launch config dropdown + Run button */}
      <div className="px-3 pb-2 flex gap-1">
        <div className="relative flex-1">
          <button
            onClick={() => setShowDropdown(!showDropdown)}
            className="flex items-center gap-1.5 px-2 py-1 text-xs bg-[var(--vscode-input-bg)] border border-[var(--vscode-input-border)] rounded hover:border-[var(--vscode-focusBorder)] w-full"
          >
            <span className="truncate">{selectedConfig.name}</span>
            <span className="ml-auto opacity-50">&#9662;</span>
          </button>

          {showDropdown && (
            <>
              <div className="fixed inset-0 z-10" onClick={() => setShowDropdown(false)} />
              <div className="absolute left-0 right-0 z-20 mt-0.5 bg-[var(--vscode-dropdown-bg)] border border-[var(--vscode-border)] rounded shadow-lg">
                {launchConfigs.map(cfg => (
                  <button
                    key={cfg.id}
                    onClick={() => {
                      setSelectedConfig(cfg);
                      setShowDropdown(false);
                    }}
                    className={`flex items-center gap-2 w-full px-3 py-1.5 text-xs hover:bg-[var(--vscode-list-hover)] ${
                      cfg.id === selectedConfig.id ? 'text-[var(--vscode-focusBorder)]' : ''
                    }`}
                  >
                    <DebugIcon size={12} />
                    {cfg.name}
                  </button>
                ))}
              </div>
            </>
          )}
        </div>

        {/* Run/Stop button */}
        <button
          onClick={handleRun}
          className={`w-7 h-7 flex items-center justify-center rounded ${
            isRunning
              ? 'bg-[var(--vscode-error)] text-white hover:opacity-90'
              : 'bg-[var(--vscode-success)] text-white hover:opacity-90'
          }`}
          title={isRunning ? 'Stop' : 'Start Debugging'}
        >
          {isRunning ? <StopCircleIcon size={16} /> : <PlayCircleIcon size={16} />}
        </button>
      </div>

      {/* Status indicator */}
      <div className="px-3 pb-2">
        <div className={`text-[10px] flex items-center gap-1 ${isRunning ? 'text-[var(--vscode-success)]' : 'opacity-40'}`}>
          <span className={`w-1.5 h-1.5 rounded-full ${isRunning ? 'bg-[var(--vscode-success)] animate-pulse' : 'bg-[var(--vscode-fg)] opacity-30'}`} />
          {isRunning ? 'Debugging active' : 'Not running'}
        </div>
      </div>

      {/* Sections */}
      <div className="flex-1 overflow-auto">
        {/* Variables */}
        <div>
          <button
            onClick={() => toggleSection('variables')}
            className="flex items-center gap-1 w-full px-3 py-1 text-[10px] font-bold tracking-wide opacity-80 uppercase hover:bg-[var(--vscode-list-hover)]"
          >
            {sections.variables ? <ChevronDownIcon size={10} /> : <ChevronRightIcon size={10} />}
            Variables
          </button>
          {sections.variables && (
            <div>
              {mockVariables.map(v => (
                <div
                  key={v.name}
                  className="flex items-center gap-2 px-5 py-0.5 text-xs hover:bg-[var(--vscode-list-hover)] font-editor"
                >
                  <span className="opacity-60">{v.name}:</span>
                  <span className="text-[var(--vscode-info)]">{v.value}</span>
                  <span className="ml-auto opacity-30 text-[10px]">{v.type}</span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Call Stack */}
        <div className="mt-1">
          <button
            onClick={() => toggleSection('callstack')}
            className="flex items-center gap-1 w-full px-3 py-1 text-[10px] font-bold tracking-wide opacity-80 uppercase hover:bg-[var(--vscode-list-hover)]"
          >
            {sections.callstack ? <ChevronDownIcon size={10} /> : <ChevronRightIcon size={10} />}
            Call Stack
          </button>
          {sections.callstack && (
            <div>
              {mockCallStack.map((frame, i) => (
                <div
                  key={i}
                  className="flex items-center gap-2 px-5 py-0.5 text-xs hover:bg-[var(--vscode-list-hover)] cursor-pointer"
                >
                  <ListTreeIcon size={12} className="opacity-40 flex-shrink-0" />
                  <div className="flex-1 min-w-0">
                    <div className="truncate">{frame.name}</div>
                    <div className="text-[10px] opacity-40 truncate">{frame.file}:{frame.line}</div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Breakpoints */}
        <div className="mt-1">
          <button
            onClick={() => toggleSection('breakpoints')}
            className="flex items-center gap-1 w-full px-3 py-1 text-[10px] font-bold tracking-wide opacity-80 uppercase hover:bg-[var(--vscode-list-hover)]"
          >
            {sections.breakpoints ? <ChevronDownIcon size={10} /> : <ChevronRightIcon size={10} />}
            Breakpoints
          </button>
          {sections.breakpoints && (
            <div>
              {mockBreakpoints.map((bp, i) => (
                <div
                  key={i}
                  className="flex items-center gap-2 px-5 py-0.5 text-xs hover:bg-[var(--vscode-list-hover)] cursor-pointer"
                >
                  <span
                    className={`w-2 h-2 rounded-full flex-shrink-0 ${
                      bp.enabled ? 'bg-[var(--vscode-error)]' : 'bg-[var(--vscode-fg)] opacity-20'
                    }`}
                  />
                  <div className="flex-1 min-w-0">
                    <div className="truncate opacity-80">{bp.file}</div>
                    <div className="text-[10px] opacity-40">Line {bp.line}</div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
