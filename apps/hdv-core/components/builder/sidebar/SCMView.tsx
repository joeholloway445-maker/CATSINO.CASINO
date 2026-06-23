import { useState } from 'react';
import { useGitStore } from '@/lib/builder/store/gitStore';
import { PlusIcon, MinusIcon } from './ExtensionIcons';
import { GitBranchIcon } from '@/components/builder/icons';
import { CheckIcon } from '@/components/builder/icons';

export function SCMView() {
  const { branch, branches, changes, staged, commits, setBranch, stageFile, unstageFile, commit } = useGitStore();
  const [commitMessage, setCommitMessage] = useState('');
  const [showBranchDropdown, setShowBranchDropdown] = useState(false);

  const handleCommit = () => {
    if (commitMessage.trim() && staged.length > 0) {
      commit(commitMessage.trim());
      setCommitMessage('');
    }
  };

  const statusColors: Record<string, string> = {
    M: 'var(--vscode-git-modified)',
    A: 'var(--vscode-git-added)',
    D: 'var(--vscode-git-deleted)',
    U: 'var(--vscode-git-untracked)',
  };

  const statusLabels: Record<string, string> = {
    M: 'M',
    A: 'A',
    D: 'D',
    U: 'U',
  };

  return (
    <div className="flex flex-col h-full text-[var(--vscode-fg)]">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-2">
        <span className="text-xs font-bold tracking-wide opacity-80">SOURCE CONTROL</span>
      </div>

      {/* Branch selector */}
      <div className="relative px-3 pb-2">
        <button
          onClick={() => setShowBranchDropdown(!showBranchDropdown)}
          className="flex items-center gap-1.5 px-2 py-1 text-xs bg-[var(--vscode-input-bg)] border border-[var(--vscode-input-border)] rounded hover:border-[var(--vscode-focusBorder)] w-full"
        >
          <GitBranchIcon size={14} />
          <span className="truncate">{branch}</span>
          <span className="ml-auto opacity-50">&#9662;</span>
        </button>

        {showBranchDropdown && (
          <>
            <div className="fixed inset-0 z-10" onClick={() => setShowBranchDropdown(false)} />
            <div className="absolute left-3 right-3 z-20 mt-0.5 bg-[var(--vscode-dropdown-bg)] border border-[var(--vscode-border)] rounded shadow-lg">
              {branches.map(b => (
                <button
                  key={b}
                  onClick={() => {
                    setBranch(b);
                    setShowBranchDropdown(false);
                  }}
                  className={`flex items-center gap-2 w-full px-3 py-1.5 text-xs hover:bg-[var(--vscode-list-hover)] ${
                    b === branch ? 'text-[var(--vscode-focusBorder)]' : ''
                  }`}
                >
                  <GitBranchIcon size={12} />
                  {b}
                </button>
              ))}
            </div>
          </>
        )}
      </div>

      <div className="flex-1 overflow-auto">
        {/* Changes section */}
        {changes.length > 0 && (
          <div className="mt-1">
            <div className="px-4 py-1 text-[10px] font-bold tracking-wide opacity-50 uppercase flex items-center justify-between">
              <span>Changes ({changes.length})</span>
            </div>
            {changes.map(file => (
              <div
                key={file.path}
                className="flex items-center gap-1 px-3 py-0.5 text-xs hover:bg-[var(--vscode-list-hover)] group"
              >
                <span
                  className="w-3 text-center text-[10px] font-medium flex-shrink-0"
                  style={{ color: statusColors[file.status] }}
                >
                  {statusLabels[file.status]}
                </span>
                <span className="truncate flex-1">{file.path}</span>
                <button
                  onClick={() => stageFile(file.path)}
                  className="w-5 h-5 flex items-center justify-center opacity-0 group-hover:opacity-100 hover:bg-[var(--vscode-list-hover)] rounded flex-shrink-0"
                  title="Stage"
                >
                  <PlusIcon size={12} />
                </button>
              </div>
            ))}
          </div>
        )}

        {/* Staged changes section */}
        {staged.length > 0 && (
          <div className="mt-2">
            <div className="px-4 py-1 text-[10px] font-bold tracking-wide opacity-50 uppercase flex items-center justify-between">
              <span>Staged Changes ({staged.length})</span>
            </div>
            {staged.map(file => (
              <div
                key={file.path}
                className="flex items-center gap-1 px-3 py-0.5 text-xs hover:bg-[var(--vscode-list-hover)] group"
              >
                <span
                  className="w-3 text-center text-[10px] font-medium flex-shrink-0"
                  style={{ color: statusColors[file.status] }}
                >
                  {statusLabels[file.status]}
                </span>
                <span className="truncate flex-1">{file.path}</span>
                <button
                  onClick={() => unstageFile(file.path)}
                  className="w-5 h-5 flex items-center justify-center opacity-0 group-hover:opacity-100 hover:bg-[var(--vscode-list-hover)] rounded flex-shrink-0"
                  title="Unstage"
                >
                  <MinusIcon size={12} />
                </button>
              </div>
            ))}
          </div>
        )}

        {/* No changes message */}
        {changes.length === 0 && staged.length === 0 && (
          <div className="px-4 py-2 text-xs opacity-50 text-center">
            There are no changes to commit.
          </div>
        )}

        {/* Recent commits */}
        {commits.length > 0 && (
          <div className="mt-3">
            <div className="px-4 py-1 text-[10px] font-bold tracking-wide opacity-50 uppercase">
              Recent Commits
            </div>
            {commits.slice(0, 5).map(c => (
              <div key={c.hash} className="flex items-start gap-2 px-3 py-1 text-xs hover:bg-[var(--vscode-list-hover)]">
                <span className="text-[var(--vscode-git-modified)] font-mono text-[10px] mt-0.5 flex-shrink-0">
                  {c.hash}
                </span>
                <div className="flex-1 min-w-0">
                  <div className="truncate">{c.message}</div>
                  <div className="opacity-40 text-[10px]">
                    {c.author} &middot; {new Date(c.timestamp).toLocaleDateString()}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Commit message box */}
      <div className="p-3 border-t border-[var(--vscode-border)]">
        <textarea
          placeholder="Message (Ctrl+Enter to commit)"
          value={commitMessage}
          onChange={(e) => setCommitMessage(e.target.value)}
          onKeyDown={(e) => {
            if (e.ctrlKey && e.key === 'Enter') {
              handleCommit();
            }
          }}
          className="w-full h-16 px-2 py-1 text-xs bg-[var(--vscode-input-bg)] border border-[var(--vscode-input-border)] rounded text-[var(--vscode-fg)] placeholder:opacity-50 outline-none focus:border-[var(--vscode-focusBorder)] resize-none"
        />
        <button
          onClick={handleCommit}
          disabled={!commitMessage.trim() || staged.length === 0}
          className="mt-2 w-full px-3 py-1.5 text-xs bg-[var(--vscode-button-bg)] text-white rounded hover:opacity-90 disabled:opacity-40 disabled:cursor-not-allowed flex items-center justify-center gap-1"
        >
          <CheckIcon size={12} />
          Commit
        </button>
      </div>
    </div>
  );
}
