export function getLanguageFromFilename(filename: string): string {
  const ext = filename.split('.').pop()?.toLowerCase() || '';
  const map: Record<string, string> = {
    js: 'javascript',
    jsx: 'javascriptreact',
    ts: 'typescript',
    tsx: 'typescriptreact',
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
    dockerfile: 'dockerfile',
    md: 'markdown',
    txt: 'plaintext',
    xml: 'xml',
    svg: 'xml',
    vue: 'vue',
    svelte: 'svelte',
  };
  return map[ext] || 'plaintext';
}

export function getLanguageLabel(language: string): string {
  const labels: Record<string, string> = {
    javascript: 'JavaScript',
    javascriptreact: 'JavaScript React',
    typescript: 'TypeScript',
    typescriptreact: 'TypeScript React',
    python: 'Python',
    go: 'Go',
    rust: 'Rust',
    java: 'Java',
    cpp: 'C++',
    c: 'C',
    html: 'HTML',
    css: 'CSS',
    scss: 'SCSS',
    json: 'JSON',
    yaml: 'YAML',
    sql: 'SQL',
    shell: 'Shell',
    dockerfile: 'Dockerfile',
    markdown: 'Markdown',
    plaintext: 'Plain Text',
    xml: 'XML',
    vue: 'Vue',
    svelte: 'Svelte',
  };
  return labels[language] || language;
}
