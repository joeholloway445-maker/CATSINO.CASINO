import { useState, useCallback, useMemo, useRef } from 'react';
import { useFileSystemStore, type FileNode } from '@/lib/builder/store/fileSystemStore';
import { useEditorStore } from '@/lib/builder/store/editorStore';
import { getLanguageFromFilename } from '@/lib/builder/utils/language';
import { SearchIcon } from '@/components/builder/icons';
import { CaseSensitiveIcon, WholeWordIcon, RegexIcon, ReplaceIcon, ReplaceAllIcon } from './ExtensionIcons';

interface SearchResult {
  path: string;
  name: string;
  line: number;
  content: string;
  matchStart: number;
  matchEnd: number;
  language: string;
}

function getAllFiles(nodes: FileNode[]): FileNode[] {
  const files: FileNode[] = [];
  for (const node of nodes) {
    if (node.type === 'file') {
      files.push(node);
    }
    if (node.children) {
      files.push(...getAllFiles(node.children));
    }
  }
  return files;
}

function escapeRegExp(string: string): string {
  return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

export function SearchView() {
  const { root } = useFileSystemStore();
  const { openFile } = useEditorStore();
  const [query, setQuery] = useState('');
  const [replaceText, setReplaceText] = useState('');
  const [showReplace, setShowReplace] = useState(false);
  const [matchCase, setMatchCase] = useState(false);
  const [wholeWord, setWholeWord] = useState(false);
  const [useRegex, setUseRegex] = useState(false);
  const [results, setResults] = useState<SearchResult[]>([]);
  const [hasSearched, setHasSearched] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const allFiles = useMemo(() => getAllFiles(root), [root]);

  const performSearch = useCallback(() => {
    if (!query.trim()) {
      setResults([]);
      setHasSearched(true);
      return;
    }

    const searchResults: SearchResult[] = [];

    for (const file of allFiles) {
      if (!file.content) continue;

      const lines = file.content.split('\n');
      let regex: RegExp;

      try {
        if (useRegex) {
          const flags = matchCase ? 'g' : 'gi';
          regex = new RegExp(query, flags);
        } else {
          const escaped = escapeRegExp(query);
          const wordBoundary = wholeWord ? `\\b${escaped}\\b` : escaped;
          const flags = matchCase ? 'g' : 'gi';
          regex = new RegExp(wordBoundary, flags);
        }
      } catch {
        // Invalid regex
        continue;
      }

      for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        const matches = Array.from(line.matchAll(regex));
        for (const match of matches) {
          if (match.index !== undefined) {
            searchResults.push({
              path: file.path,
              name: file.name,
              line: i + 1,
              content: line,
              matchStart: match.index,
              matchEnd: match.index + match[0].length,
              language: file.language || 'plaintext',
            });
          }
        }
      }
    }

    setResults(searchResults);
    setHasSearched(true);
  }, [query, allFiles, matchCase, wholeWord, useRegex]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      performSearch();
    }
  }, [performSearch]);

  const handleResultClick = useCallback((result: SearchResult) => {
    const file = allFiles.find(f => f.path === result.path);
    if (file && file.content) {
      const lang = getLanguageFromFilename(file.name);
      openFile(file.path, file.name, file.content, lang);
    }
  }, [allFiles, openFile]);

  // Group results by file
  const groupedResults = useMemo(() => {
    const groups: Record<string, SearchResult[]> = {};
    for (const r of results) {
      if (!groups[r.path]) {
        groups[r.path] = [];
      }
      groups[r.path].push(r);
    }
    return groups;
  }, [results]);

  const toggleButtons = [
    { id: 'case', icon: CaseSensitiveIcon, active: matchCase, onClick: () => setMatchCase(!matchCase), title: 'Match Case' },
    { id: 'word', icon: WholeWordIcon, active: wholeWord, onClick: () => setWholeWord(!wholeWord), title: 'Match Whole Word' },
    { id: 'regex', icon: RegexIcon, active: useRegex, onClick: () => setUseRegex(!useRegex), title: 'Use Regular Expression' },
  ];

  return (
    <div className="flex flex-col h-full text-[var(--vscode-fg)]">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-2">
        <span className="text-xs font-bold tracking-wide opacity-80">SEARCH</span>
      </div>

      {/* Search input */}
      <div className="px-3 space-y-1">
        <div className="relative">
          <SearchIcon size={14} className="absolute left-2 top-1/2 -translate-y-1/2 opacity-50" />
          <input
            ref={inputRef}
            type="text"
            placeholder="Search"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
            className="w-full pl-7 pr-6 py-1 text-xs bg-[var(--vscode-input-bg)] border border-[var(--vscode-input-border)] rounded text-[var(--vscode-fg)] placeholder:opacity-50 outline-none focus:border-[var(--vscode-focusBorder)]"
          />
          <button
            onClick={() => setShowReplace(!showReplace)}
            className="absolute right-1 top-1/2 -translate-y-1/2 w-5 h-5 flex items-center justify-center opacity-50 hover:opacity-100 hover:bg-[var(--vscode-list-hover)] rounded"
            title="Toggle Replace"
          >
            <ReplaceIcon size={12} />
          </button>
        </div>

        {/* Replace input (collapsible) */}
        {showReplace && (
          <div className="relative">
            <input
              type="text"
              placeholder="Replace"
              value={replaceText}
              onChange={(e) => setReplaceText(e.target.value)}
              className="w-full pl-7 pr-6 py-1 text-xs bg-[var(--vscode-input-bg)] border border-[var(--vscode-input-border)] rounded text-[var(--vscode-fg)] placeholder:opacity-50 outline-none focus:border-[var(--vscode-focusBorder)]"
            />
            <ReplaceAllIcon size={14} className="absolute left-2 top-1/2 -translate-y-1/2 opacity-50" />
          </div>
        )}

        {/* Toggle buttons */}
        <div className="flex gap-1 pt-1">
          {toggleButtons.map(btn => (
            <button
              key={btn.id}
              title={btn.title}
              onClick={btn.onClick}
              className={`w-6 h-6 flex items-center justify-center rounded ${
                btn.active
                  ? 'bg-[var(--vscode-list-active)] text-[var(--vscode-fg)]'
                  : 'text-[var(--vscode-fg)] opacity-50 hover:opacity-80 hover:bg-[var(--vscode-list-hover)]'
              }`}
            >
              <btn.icon size={14} />
            </button>
          ))}
        </div>
      </div>

      {/* Results */}
      <div className="flex-1 overflow-auto mt-2">
        {!hasSearched && query.trim() === '' && (
          <div className="px-4 py-2 text-xs opacity-50">
            Type a search term and press Enter to search across files.
          </div>
        )}
        {hasSearched && results.length === 0 && query.trim() !== '' && (
          <div className="px-4 py-2 text-xs opacity-50">
            No results found for &quot;{query}&quot;.
          </div>
        )}

        {Object.entries(groupedResults).map(([path, fileResults]) => (
          <div key={path} className="mb-1">
            {/* File header */}
            <div className="flex items-center gap-1 px-3 py-1 text-xs hover:bg-[var(--vscode-list-hover)] cursor-pointer">
              <span className="truncate font-medium opacity-80">{fileResults[0]?.name}</span>
              <span className="truncate opacity-40 ml-1">{path}</span>
              <span className="ml-auto opacity-40 text-[10px]">{fileResults.length} results</span>
            </div>
            {/* Line results */}
            {fileResults.map((result, idx) => {
              const before = result.content.slice(0, result.matchStart);
              const match = result.content.slice(result.matchStart, result.matchEnd);
              const after = result.content.slice(result.matchEnd);

              return (
                <div
                  key={idx}
                  className="flex items-start gap-2 px-3 py-0.5 cursor-pointer hover:bg-[var(--vscode-list-hover)] text-xs font-editor"
                  onClick={() => handleResultClick(result)}
                >
                  <span className="opacity-40 w-8 text-right flex-shrink-0 select-none">
                    {result.line}
                  </span>
                  <span className="truncate opacity-80">
                    {before}
                    <span className="bg-[#f4a460] text-black">{match}</span>
                    {after}
                  </span>
                </div>
              );
            })}
          </div>
        ))}
      </div>
    </div>
  );
}
