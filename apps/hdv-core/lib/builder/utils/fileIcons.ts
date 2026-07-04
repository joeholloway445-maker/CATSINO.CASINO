export type FileIconType =
  | 'react'
  | 'react_ts'
  | 'javascript'
  | 'typescript'
  | 'html'
  | 'css'
  | 'json'
  | 'markdown'
  | 'python'
  | 'go'
  | 'rust'
  | 'java'
  | 'cpp'
  | 'shell'
  | 'docker'
  | 'yaml'
  | 'xml'
  | 'svg'
  | 'vue'
  | 'svelte'
  | 'sql'
  | 'git'
  | 'config'
  | 'folder'
  | 'folder-open'
  | 'file';

export function getFileIconType(filename: string, isFolder: boolean = false, isOpen?: boolean): FileIconType {
  if (isFolder) {
    return isOpen ? 'folder-open' : 'folder';
  }

  const ext = filename.split('.').pop()?.toLowerCase() || '';
  const name = filename.toLowerCase();

  if (name === 'dockerfile' || name === '.dockerignore') return 'docker';
  if (name === '.gitignore') return 'git';
  if (name === 'package.json' || name === 'tsconfig.json' || name === 'vite.config.ts') return 'config';

  const extMap: Record<string, FileIconType> = {
    tsx: 'react_ts',
    jsx: 'react',
    ts: 'typescript',
    js: 'javascript',
    html: 'html',
    css: 'css',
    scss: 'css',
    json: 'json',
    md: 'markdown',
    py: 'python',
    go: 'go',
    rs: 'rust',
    java: 'java',
    cpp: 'cpp',
    c: 'cpp',
    h: 'cpp',
    sh: 'shell',
    bash: 'shell',
    yaml: 'yaml',
    yml: 'yaml',
    xml: 'xml',
    svg: 'svg',
    vue: 'vue',
    svelte: 'svelte',
    sql: 'sql',
  };

  return extMap[ext] || 'file';
}

export function getFileIconColor(iconType: FileIconType): string {
  const colors: Record<FileIconType, string> = {
    react: '#61dafb',
    react_ts: '#3178c6',
    javascript: '#f1e05a',
    typescript: '#3178c6',
    html: '#e34c26',
    css: '#563d7c',
    json: '#f1e05a',
    markdown: '#083fa1',
    python: '#3572A5',
    go: '#00ADD8',
    rust: '#dea584',
    java: '#b07219',
    cpp: '#f34b7d',
    shell: '#89e051',
    docker: '#384d54',
    yaml: '#cb171e',
    xml: '#0060ac',
    svg: '#ff9900',
    vue: '#41b883',
    svelte: '#ff3e00',
    sql: '#dad8d8',
    git: '#f14e32',
    config: '#cccccc',
    folder: '#dcb67a',
    'folder-open': '#dcb67a',
    file: '#cccccc',
  };
  return colors[iconType] || '#cccccc';
}
