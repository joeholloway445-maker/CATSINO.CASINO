import { useState } from 'react';
import * as Popover from '@radix-ui/react-popover';
import { useStatusBarStore } from '@/lib/builder/store/statusBarStore';
import { useSidebarStore } from '@/lib/builder/store/sidebarStore';
import { GitBranchIcon, WarningIcon, ErrorIcon, BellIcon, CheckIcon } from '@/components/builder/icons';

const BRANCHES = ['main', 'develop', 'feature/auth'];
const INDENTS = ['Spaces: 2', 'Spaces: 4', 'Spaces: 8', 'Tab'];
const ENCODINGS = ['UTF-8', 'UTF-16', 'Latin-1'];
const EOLS = ['LF', 'CRLF'];
const LANGUAGES = [
  'JavaScript', 'TypeScript', 'Python', 'Go', 'Rust', 'Java',
  'C++', 'HTML', 'CSS', 'SCSS', 'JSON', 'YAML', 'Markdown',
  'SQL', 'Shell', 'Dockerfile', 'Vue', 'XML',
];

function PopoverPicker({
  trigger,
  options,
  value,
  onChange,
}: {
  trigger: React.ReactNode;
  options: string[];
  value: string;
  onChange: (v: string) => void;
}) {
  const [open, setOpen] = useState(false);
  return (
    <Popover.Root open={open} onOpenChange={setOpen}>
      <Popover.Trigger asChild>
        <button
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 4,
            padding: '0 6px',
            height: 22,
            background: 'transparent',
            border: 'none',
            color: 'inherit',
            cursor: 'pointer',
            fontSize: 12,
            fontWeight: 400,
            fontFamily: 'inherit',
          }}
          onMouseEnter={(e) => { e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.12)'; }}
          onMouseLeave={(e) => { e.currentTarget.style.backgroundColor = 'transparent'; }}
        >
          {trigger}
        </button>
      </Popover.Trigger>
      <Popover.Portal>
        <Popover.Content
          style={{
            backgroundColor: '#252526',
            border: '1px solid #454545',
            borderRadius: 4,
            boxShadow: '0 4px 12px rgba(0,0,0,0.4)',
            zIndex: 10000,
            minWidth: 140,
            padding: '4px 0',
          }}
        >
          {options.map((opt) => (
            <div
              key={opt}
              onClick={() => { onChange(opt); setOpen(false); }}
              style={{
                padding: '5px 12px',
                fontSize: 12,
                cursor: 'pointer',
                color: '#cccccc',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                backgroundColor: opt === value ? 'var(--vscode-list-active)' : 'transparent',
              }}
              onMouseEnter={(e) => { if (opt !== value) e.currentTarget.style.backgroundColor = 'var(--vscode-list-hover)'; }}
              onMouseLeave={(e) => { if (opt !== value) e.currentTarget.style.backgroundColor = 'transparent'; }}
            >
              <span>{opt}</span>
              {opt === value && <span style={{ fontSize: 10 }}>{'\u2713'}</span>}
            </div>
          ))}
        </Popover.Content>
      </Popover.Portal>
    </Popover.Root>
  );
}

export function StatusBar() {
  const {
    branch,
    language,
    line,
    col,
    problems,
    isFormatting,
    encoding,
    eol,
    indentation,
  } = useStatusBarStore();
  const sidebar = useSidebarStore();

  const hasProblems = problems.errors > 0 || problems.warnings > 0;

  return (
    <div
      style={{
        height: 22,
        backgroundColor: 'var(--vscode-statusBar-bg)',
        color: 'var(--vscode-statusBar-fg)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '0 8px',
        fontSize: 12,
        fontWeight: 400,
        flexShrink: 0,
        userSelect: 'none',
      }}
    >
      {/* Left section */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 0 }}>
        {/* Branch */}
        <PopoverPicker
          trigger={<><GitBranchIcon size={14} /><span>{branch}</span></>}
          options={BRANCHES}
          value={branch}
          onChange={(v) => useStatusBarStore.setState({ branch: v })}
        />

        {/* Sync icon */}
        <StatusBarItem>
          <svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor">
            <path d="M2.5 7.5A5.5 5.5 0 018 2.5V0l4 3-4 3V4.5a3.5 3.5 0 103.5 3.5h2A5.5 5.5 0 012.5 7.5z" />
          </svg>
        </StatusBarItem>

        {/* Problems — clickable */}
        <button
          onClick={() => sidebar.setView('explorer')}
          style={{
            display: 'flex', alignItems: 'center', gap: 4, padding: '0 6px',
            height: 22, background: 'transparent', border: 'none',
            color: 'inherit', cursor: 'pointer', fontSize: 12, fontWeight: 400,
          }}
          onMouseEnter={(e) => { e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.12)'; }}
          onMouseLeave={(e) => { e.currentTarget.style.backgroundColor = 'transparent'; }}
        >
          {hasProblems ? (
            <>
              {problems.errors > 0 && <><ErrorIcon size={14} /><span>{problems.errors}</span></>}
              {problems.warnings > 0 && <><WarningIcon size={14} /><span>{problems.warnings}</span></>}
            </>
          ) : (
            <CheckIcon size={14} />
          )}
        </button>
      </div>

      {/* Right section */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 0 }}>
        {/* Cursor position */}
        <StatusBarItem>
          <span>Ln {line}, Col {col}</span>
        </StatusBarItem>

        {/* Indentation */}
        <PopoverPicker
          trigger={<span>{indentation}</span>}
          options={INDENTS}
          value={indentation}
          onChange={(v) => useStatusBarStore.setState({ indentation: v })}
        />

        {/* Encoding */}
        <PopoverPicker
          trigger={<span>{encoding}</span>}
          options={ENCODINGS}
          value={encoding}
          onChange={(v) => useStatusBarStore.setState({ encoding: v })}
        />

        {/* EOL */}
        <PopoverPicker
          trigger={<span>{eol}</span>}
          options={EOLS}
          value={eol}
          onChange={(v) => useStatusBarStore.setState({ eol: v })}
        />

        {/* Language */}
        <PopoverPicker
          trigger={<span>{language}</span>}
          options={LANGUAGES}
          value={language}
          onChange={(v) => useStatusBarStore.setState({ language: v })}
        />

        {/* Prettier */}
        <button
          onClick={() => {
            const toast = document.createElement('div');
            toast.textContent = isFormatting ? 'Formatting...' : 'Formatted with Prettier';
            toast.style.cssText = 'position:fixed;bottom:40px;left:50%;transform:translateX(-50%);background:#252526;color:#ccc;padding:8px 16px;border-radius:4px;font-size:13px;z-index:9999;border:1px solid #454545';
            document.body.appendChild(toast);
            setTimeout(() => toast.remove(), 2000);
          }}
          style={{
            display: 'flex', alignItems: 'center', gap: 4, padding: '0 6px',
            height: 22, background: 'transparent', border: 'none',
            color: 'inherit', cursor: 'pointer', fontSize: 12, fontWeight: 400,
          }}
          onMouseEnter={(e) => { e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.12)'; }}
          onMouseLeave={(e) => { e.currentTarget.style.backgroundColor = 'transparent'; }}
        >
          <svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor">
            <path d="M1.5 4h1v8h-1V4zm2 0h1.5v8H3.5V4zm2 0h1v8h-1V4zm2 0h2v8h-2V4zm2.5 0h1v8H10V4zm2 0h2.5v8H12V4z" />
          </svg>
          <span>{isFormatting ? 'Formatting...' : 'Prettier'}</span>
        </button>

        {/* Notifications */}
        <StatusBarItem>
          <BellIcon size={14} />
        </StatusBarItem>
      </div>
    </div>
  );
}

function StatusBarItem({ children }: { children: React.ReactNode }) {
  return (
    <button
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 4,
        padding: '0 6px',
        height: 22,
        background: 'transparent',
        border: 'none',
        color: 'inherit',
        cursor: 'pointer',
        fontSize: 12,
        fontWeight: 400,
        fontFamily: 'inherit',
      }}
      onMouseEnter={(e) => { e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.12)'; }}
      onMouseLeave={(e) => { e.currentTarget.style.backgroundColor = 'transparent'; }}
    >
      {children}
    </button>
  );
}
