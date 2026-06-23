import { create } from 'zustand';

export interface GitFile { path: string; status: 'M' | 'A' | 'D' | 'U'; }
export interface GitCommit { hash: string; message: string; author: string; timestamp: number; branch: string; }

interface GitState {
  branch: string;
  branches: string[];
  changes: GitFile[];
  staged: GitFile[];
  commits: GitCommit[];
  setBranch: (b: string) => void;
  stageFile: (path: string) => void;
  unstageFile: (path: string) => void;
  discardFile: (path: string) => void;
  commit: (message: string) => void;
}

const initialChanges: GitFile[] = [
  { path: 'src/App.tsx', status: 'M' },
  { path: 'src/components/Header.tsx', status: 'M' },
  { path: 'package.json', status: 'M' },
  { path: 'src/types/index.ts', status: 'A' },
];

const initialStaged: GitFile[] = [
  { path: 'README.md', status: 'M' },
];

const initialCommits: GitCommit[] = [
  { hash: 'a1b2c3d', message: 'feat: add user authentication', author: 'Developer', timestamp: Date.now() - 86400000 * 2, branch: 'main' },
  { hash: 'e4f5g6h', message: 'fix: resolve header styling', author: 'Developer', timestamp: Date.now() - 86400000, branch: 'main' },
  { hash: 'i7j8k9l', message: 'docs: update README', author: 'Developer', timestamp: Date.now() - 3600000, branch: 'main' },
];

export const useGitStore = create<GitState>((set) => ({
  branch: 'main',
  branches: ['main', 'develop', 'feature/auth'],
  changes: initialChanges,
  staged: initialStaged,
  commits: initialCommits,
  setBranch: (b) => set({ branch: b }),
  stageFile: (path) => set((s) => {
    const file = s.changes.find(f => f.path === path);
    if (!file) return s;
    return { changes: s.changes.filter(f => f.path !== path), staged: [...s.staged, file] };
  }),
  unstageFile: (path) => set((s) => {
    const file = s.staged.find(f => f.path === path);
    if (!file) return s;
    return { staged: s.staged.filter(f => f.path !== path), changes: [...s.changes, file] };
  }),
  discardFile: (path) => set((s) => ({ changes: s.changes.filter(f => f.path !== path) })),
  commit: (message) => set((s) => {
    if (s.staged.length === 0) return s;
    const newCommit: GitCommit = {
      hash: Math.random().toString(36).substring(2, 9),
      message,
      author: 'User',
      timestamp: Date.now(),
      branch: s.branch,
    };
    return { staged: [], commits: [newCommit, ...s.commits] };
  }),
}));
