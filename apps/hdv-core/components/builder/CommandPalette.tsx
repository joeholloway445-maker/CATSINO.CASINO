import { useState, useEffect } from 'react';
import { Command } from 'cmdk';
import { useSidebarStore } from '@/lib/builder/store/sidebarStore';
import { useEditorStore } from '@/lib/builder/store/editorStore';
import { useFileSystemStore, type FileNode } from '@/lib/builder/store/fileSystemStore';
import { useThemeStore } from '@/lib/builder/store/themeStore';

export function CommandPalette() {
  const [open, setOpen] = useState(false);
  const [mode, setMode] = useState<'command' | 'file'>('command');
  const [search, setSearch] = useState('');

  const sidebar = useSidebarStore();
  const editor = useEditorStore();
  const fs = useFileSystemStore();
  const theme = useThemeStore();


  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.shiftKey && e.key === 'p') {
        e.preventDefault();
        setMode('command');
        setOpen(true);
      } else if ((e.metaKey || e.ctrlKey) && e.key === 'p' && !e.shiftKey) {
        e.preventDefault();
        setMode('file');
        setOpen(true);
      } else if (e.key === 'Escape' && open) {
        e.preventDefault();
        setOpen(false);
      }
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [open]);

  const run = (action: () => void) => {
    action();
    setOpen(false);
    setSearch('');
  };

  const commands = [
    { label: 'Toggle Sidebar', shortcut: 'Ctrl+B', action: () => run(() => sidebar.toggle()) },
    { label: 'Toggle Panel', shortcut: 'Ctrl+J', action: () => run(() => window.dispatchEvent(new CustomEvent('vscode:command', { detail: { command: 'togglePanel' } }))) },
    { label: 'Toggle Terminal', shortcut: 'Ctrl+`', action: () => run(() => window.dispatchEvent(new CustomEvent('vscode:command', { detail: { command: 'toggleTerminal' } }))) },
    { label: 'New File', shortcut: 'Ctrl+N', action: () => run(() => editor.setActiveTab(editor.newUntitled())) },
    { label: 'Save', shortcut: 'Ctrl+S', action: () => run(() => { const t = editor.getActiveTab(); if (t) editor.markClean(t.id); }) },
    { label: 'Explorer', shortcut: 'Ctrl+Shift+E', action: () => run(() => sidebar.setView('explorer')) },
    { label: 'Search', shortcut: 'Ctrl+Shift+F', action: () => run(() => sidebar.setView('search')) },
    { label: 'Source Control', shortcut: 'Ctrl+Shift+G', action: () => run(() => sidebar.setView('scm')) },
    { label: 'Run and Debug', shortcut: 'Ctrl+Shift+D', action: () => run(() => sidebar.setView('run')) },
    { label: 'Extensions', shortcut: 'Ctrl+Shift+X', action: () => run(() => sidebar.setView('extensions')) },
    { label: 'Problems', shortcut: 'Ctrl+Shift+M', action: () => run(() => window.dispatchEvent(new CustomEvent('vscode:command', { detail: { command: 'togglePanel' } }))) },
    { label: 'Output', action: () => run(() => window.dispatchEvent(new CustomEvent('vscode:command', { detail: { command: 'togglePanel' } }))) },
    { label: 'Debug Console', action: () => run(() => window.dispatchEvent(new CustomEvent('vscode:command', { detail: { command: 'togglePanel' } }))) },
    { label: 'Format Document', shortcut: 'Shift+Alt+F', action: () => run(() => window.dispatchEvent(new CustomEvent('vscode:command', { detail: { command: 'formatDocument' } }))) },
    { label: 'Theme: Dark+', action: () => run(() => theme.setTheme('dark')) },
    { label: 'Theme: Light+', action: () => run(() => theme.setTheme('light')) },
    { label: 'Theme: Solarized Dark', action: () => run(() => theme.setTheme('solarized')) },
    { label: 'Theme: Monokai', action: () => run(() => theme.setTheme('monokai')) },
    { label: 'Theme: GitHub', action: () => run(() => theme.setTheme('github')) },
    { label: 'Welcome', action: () => run(() => window.dispatchEvent(new CustomEvent('vscode:command', { detail: { command: 'welcome' } }))) },
    { label: 'Close Editor', shortcut: 'Ctrl+W', action: () => run(() => { const t = editor.getActiveTab(); if (t) editor.closeTab(t.id); }) },
    { label: 'Undo', shortcut: 'Ctrl+Z', action: () => run(() => window.dispatchEvent(new CustomEvent('vscode:command', { detail: { command: 'undo' } }))) },
    { label: 'Redo', shortcut: 'Ctrl+Y', action: () => run(() => window.dispatchEvent(new CustomEvent('vscode:command', { detail: { command: 'redo' } }))) },
    { label: 'Find', shortcut: 'Ctrl+F', action: () => run(() => window.dispatchEvent(new CustomEvent('vscode:command', { detail: { command: 'find' } }))) },
    { label: 'Replace', shortcut: 'Ctrl+H', action: () => run(() => window.dispatchEvent(new CustomEvent('vscode:command', { detail: { command: 'replace' } }))) },
    { label: 'Select All', shortcut: 'Ctrl+A', action: () => run(() => window.dispatchEvent(new CustomEvent('vscode:command', { detail: { command: 'selectAll' } }))) },
    { label: 'Go to File', shortcut: 'Ctrl+P', action: () => { setMode('file'); setSearch(''); } },
  ];

  // Collect all files from fileSystemStore
  const allFiles: { name: string; path: string; content: string; language: string }[] = [];
  const walk = (nodes: FileNode[]) => {
    for (const n of nodes) {
      if (n.type === 'file') allFiles.push({ name: n.name, path: n.path, content: n.content || '', language: n.language || 'plaintext' });
      if (n.children) walk(n.children);
    }
  };
  walk(fs.root);

  const filteredFiles = search
    ? allFiles.filter((f) => f.name.toLowerCase().includes(search.toLowerCase()))
    : allFiles;

  if (!open) return null;

  return (
    <div
      style={{
        position: 'fixed',
        inset: 0,
        zIndex: 9999,
        backgroundColor: 'rgba(0,0,0,0.5)',
        display: 'flex',
        alignItems: 'flex-start',
        justifyContent: 'center',
        paddingTop: '15vh',
      }}
      onClick={() => setOpen(false)}
    >
      <div
        style={{
          width: 600,
          maxWidth: '90vw',
          backgroundColor: '#252526',
          border: '1px solid #454545',
          borderRadius: 6,
          boxShadow: '0 8px 32px rgba(0,0,0,0.5)',
          overflow: 'hidden',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <Command label="Command Palette">
          <div style={{ display: 'flex', alignItems: 'center', padding: '8px 12px', borderBottom: '1px solid #454545' }}>
            <span style={{ color: '#858585', fontSize: 13, marginRight: 8 }}>
              {mode === 'command' ? '>' : 'Go to file'}
            </span>
            <Command.Input
              value={search}
              onValueChange={setSearch}
              placeholder={mode === 'command' ? 'Type a command' : 'Search files by name'}
              style={{
                flex: 1,
                background: 'transparent',
                border: 'none',
                outline: 'none',
                color: '#cccccc',
                fontSize: 13,
                fontFamily: '"Inter", sans-serif',
              }}
              autoFocus
            />
          </div>
          <Command.List style={{ maxHeight: 400, overflowY: 'auto' }}>
            {mode === 'command' ? (
              commands
                .filter((c) => c.label.toLowerCase().includes(search.toLowerCase()))
                .map((c) => (
                  <Command.Item
                    key={c.label}
                    onSelect={c.action}
                    style={{
                      padding: '6px 12px',
                      cursor: 'pointer',
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'center',
                      fontSize: 13,
                      color: '#cccccc',
                    }}
                  >
                    <span>{c.label}</span>
                    {c.shortcut && (
                      <span style={{ fontSize: 11, color: '#858585', fontFamily: '"Cascadia Code", monospace' }}>
                        {c.shortcut}
                      </span>
                    )}
                  </Command.Item>
                ))
            ) : (
              filteredFiles.map((f) => (
                <Command.Item
                  key={f.path}
                  onSelect={() => run(() => editor.openFile(f.path, f.name, f.content, f.language))}
                  style={{
                    padding: '6px 12px',
                    cursor: 'pointer',
                    display: 'flex',
                    justifyContent: 'space-between',
                    alignItems: 'center',
                    fontSize: 13,
                    color: '#cccccc',
                  }}
                >
                  <span>{f.name}</span>
                  <span style={{ fontSize: 11, color: '#858585' }}>{f.path}</span>
                </Command.Item>
              ))
            )}
          </Command.List>
        </Command>
      </div>
    </div>
  );
}
