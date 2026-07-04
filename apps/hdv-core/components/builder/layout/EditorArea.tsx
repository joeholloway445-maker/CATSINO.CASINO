import { useRef, useCallback } from 'react';
import Editor from '@monaco-editor/react';
import type * as monaco from 'monaco-editor';
import { useEditorStore } from '@/lib/builder/store/editorStore';
import { WelcomePage } from './WelcomePage';

const LANG_MAP: Record<string, string> = {
  ts: 'typescript',
  tsx: 'typescript',
  js: 'javascript',
  jsx: 'javascript',
  py: 'python',
  go: 'go',
  rs: 'rust',
  java: 'java',
  cpp: 'cpp',
  c: 'c',
  h: 'c',
  html: 'html',
  css: 'css',
  scss: 'scss',
  json: 'json',
  yaml: 'yaml',
  yml: 'yaml',
  sql: 'sql',
  sh: 'shell',
  bash: 'shell',
  md: 'markdown',
  markdown: 'markdown',
  dockerfile: 'dockerfile',
  xml: 'xml',
  svg: 'xml',
  vue: 'html',
  svelte: 'html',
  txt: 'plaintext',
};

function detectLang(path: string): string {
  const ext = path.split('.').pop()?.toLowerCase() || '';
  if (path.toLowerCase().startsWith('dockerfile')) return 'dockerfile';
  return LANG_MAP[ext] || 'plaintext';
}

const THEME_DEFS: Record<string, monaco.editor.IStandaloneThemeData> = {
  'vs-dark': {
    base: 'vs-dark' as const,
    inherit: true,
    rules: [
      { token: 'comment', foreground: '6A9955' },
      { token: 'keyword', foreground: '569CD6' },
      { token: 'identifier', foreground: '9CDCFE' },
      { token: 'string', foreground: 'CE9178' },
      { token: 'number', foreground: 'B5CEA8' },
      { token: 'type', foreground: '4EC9B0' },
      { token: 'function', foreground: 'DCDCAA' },
    ],
    colors: {
      'editor.background': '#1E1E1E',
      'editor.foreground': '#D4D4D4',
      'editor.lineHighlightBackground': '#2D2D2D',
      'editor.selectionBackground': '#264F78',
    },
  },
  'vs-light': {
    base: 'vs' as const,
    inherit: true,
    rules: [
      { token: 'comment', foreground: '008000' },
      { token: 'keyword', foreground: '0000FF' },
      { token: 'string', foreground: 'A31515' },
      { token: 'number', foreground: '098658' },
    ],
    colors: {
      'editor.background': '#FFFFFF',
      'editor.foreground': '#000000',
    },
  },
  'solarized': {
    base: 'vs-dark' as const,
    inherit: true,
    rules: [
      { token: 'comment', foreground: '586E75' },
      { token: 'keyword', foreground: 'CB4B16' },
      { token: 'string', foreground: '2AA198' },
      { token: 'number', foreground: 'D33682' },
    ],
    colors: {
      'editor.background': '#002B36',
      'editor.foreground': '#839496',
      'editor.selectionBackground': '#073642',
    },
  },
  'monokai': {
    base: 'vs-dark' as const,
    inherit: true,
    rules: [
      { token: 'comment', foreground: '75715E' },
      { token: 'keyword', foreground: 'F92672' },
      { token: 'string', foreground: 'E6DB74' },
      { token: 'number', foreground: 'AE81FF' },
    ],
    colors: {
      'editor.background': '#272822',
      'editor.foreground': '#F8F8F2',
      'editor.selectionBackground': '#49483E',
    },
  },
  'github': {
    base: 'vs' as const,
    inherit: true,
    rules: [
      { token: 'comment', foreground: '6A737D' },
      { token: 'keyword', foreground: 'D73A49' },
      { token: 'string', foreground: '032F62' },
      { token: 'number', foreground: '005CC5' },
    ],
    colors: {
      'editor.background': '#FFFFFF',
      'editor.foreground': '#24292E',
      'editor.selectionBackground': '#0366D6',
    },
  },
};

export const editorRef = { current: null as monaco.editor.IStandaloneCodeEditor | null };

export function EditorArea() {
  const { tabs, activeTabId, updateTabContent, markClean, markDirty } = useEditorStore();
  const active = tabs.find((t) => t.id === activeTabId);
  const monacoRef = useRef<typeof monaco | null>(null);

  const handleMount = useCallback((editor: monaco.editor.IStandaloneCodeEditor, monacoInstance: typeof monaco) => {
    editorRef.current = editor;
    monacoRef.current = monacoInstance;

    // Register themes
    Object.entries(THEME_DEFS).forEach(([name, def]) => {
      monacoInstance.editor.defineTheme(name, def);
    });

    // Cmd+S
    editor.addCommand(monacoInstance.KeyMod.CtrlCmd | monacoInstance.KeyCode.KeyS, () => {
      const tab = useEditorStore.getState().getActiveTab();
      if (tab) markClean(tab.id);
    });

    // Theme
    const theme = document.documentElement.getAttribute('data-theme') || 'vs-dark';
    monacoInstance.editor.setTheme(theme);
  }, [markClean]);

  const handleChange = useCallback((value: string | undefined) => {
    if (!active || value === undefined) return;
    updateTabContent(active.id, value);
    markDirty(active.id);
  }, [active, updateTabContent, markDirty]);

  if (!active) {
    return (
      <div style={{ flex: 1, backgroundColor: 'var(--vscode-editor-bg)', overflow: 'auto' }}>
        <WelcomePage />
      </div>
    );
  }

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
      <Editor
        height="100%"
        language={detectLang(active.path)}
        value={active.content}
        path={active.path}
        theme="vs-dark"
        onMount={handleMount}
        onChange={handleChange}
        options={{
          readOnly: false,
          fontFamily: '"Cascadia Code", "SF Mono", Menlo, Monaco, monospace',
          fontSize: 13,
          fontLigatures: true,
          automaticLayout: true,
          minimap: { enabled: true },
          scrollBeyondLastLine: false,
          lineNumbers: 'on',
          renderWhitespace: 'selection',
          tabSize: 2,
          insertSpaces: true,
          wordWrap: 'off',
          cursorBlinking: 'blink',
          bracketPairColorization: { enabled: true },
          formatOnPaste: true,
          formatOnType: true,
        }}
      />
    </div>
  );
}
