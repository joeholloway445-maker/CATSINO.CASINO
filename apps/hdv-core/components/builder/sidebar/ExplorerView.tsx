import { useState, useCallback } from 'react';
import { useFileSystemStore, type FileNode } from '@/lib/builder/store/fileSystemStore';
import { useEditorStore } from '@/lib/builder/store/editorStore';
import { getLanguageFromFilename } from '@/lib/builder/utils/language';
import {
  NewFileIcon,
  NewFolderIcon,
  RefreshExplorerIcon,
  CollapseAllIcon,
} from '@/components/builder/icons';
import { FileTreeNode } from './FileTreeNode';

export function ExplorerView() {
  const { root, expandedFolders, toggleFolder, selectedNodeId, setSelectedNode, collapseFolder } = useFileSystemStore();
  const { openFile, tabs, activeTabId } = useEditorStore();
  const [expandedIds, setExpandedIds] = useState<Set<string>>(new Set());

  // Initialize expandedIds from store's expandedFolders
  useState(() => {
    setExpandedIds(new Set(expandedFolders));
  });

  const handleToggle = useCallback((node: FileNode) => {
    toggleFolder(node.id);
    setExpandedIds(prev => {
      const next = new Set(prev);
      if (next.has(node.id)) {
        next.delete(node.id);
      } else {
        next.add(node.id);
      }
      return next;
    });
  }, [toggleFolder]);

  const handleSelect = useCallback((node: FileNode) => {
    setSelectedNode(node.id);
    if (node.type === 'file' && node.content !== undefined) {
      const lang = getLanguageFromFilename(node.name);
      openFile(node.path, node.name, node.content, lang);
    }
  }, [setSelectedNode, openFile]);

  const handleCollapseAll = useCallback(() => {
    // Collapse all folders in the store
    const allExpanded = Array.from(expandedIds);
    allExpanded.forEach(id => collapseFolder(id));
    setExpandedIds(new Set());
  }, [expandedIds, collapseFolder]);

  const openEditors = tabs.filter(t => !t.path.startsWith('Untitled'));

  return (
    <div className="flex flex-col h-full text-[var(--vscode-fg)]">
      {/* Section header */}
      <div className="flex items-center justify-between px-3 py-1">
        <span style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.5px', textTransform: 'uppercase', opacity: 0.8 }}>EXPLORER</span>
        <div className="flex gap-0.5">
          <button
            title="New File"
            className="w-6 h-6 flex items-center justify-center hover:bg-[var(--vscode-list-hover)] rounded opacity-60 hover:opacity-100"
          >
            <NewFileIcon size={16} />
          </button>
          <button
            title="New Folder"
            className="w-6 h-6 flex items-center justify-center hover:bg-[var(--vscode-list-hover)] rounded opacity-60 hover:opacity-100"
          >
            <NewFolderIcon size={16} />
          </button>
          <button
            title="Refresh Explorer"
            className="w-6 h-6 flex items-center justify-center hover:bg-[var(--vscode-list-hover)] rounded opacity-60 hover:opacity-100"
          >
            <RefreshExplorerIcon size={16} />
          </button>
          <button
            title="Collapse All"
            onClick={handleCollapseAll}
            className="w-6 h-6 flex items-center justify-center hover:bg-[var(--vscode-list-hover)] rounded opacity-60 hover:opacity-100"
          >
            <CollapseAllIcon size={16} />
          </button>
        </div>
      </div>

      {/* OPEN EDITORS section */}
      {openEditors.length > 0 && (
        <div className="mt-1">
          <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.5px', textTransform: 'uppercase', opacity: 0.5, padding: '4px 16px' }}>
            Open Editors
          </div>
          {openEditors.map(tab => (
            <div
              key={tab.id}
              className={`flex items-center gap-1 py-0.5 px-4 cursor-pointer text-sm ${
                tab.id === activeTabId
                  ? 'bg-[var(--vscode-list-active)]'
                  : 'hover:bg-[var(--vscode-list-hover)]'
              }`}
              onClick={() => {
                const { setActiveTab } = useEditorStore.getState();
                setActiveTab(tab.id);
              }}
            >
              <span className="truncate text-xs">{tab.name}</span>
              {tab.isDirty && <span className="text-[var(--vscode-fg)] opacity-50 ml-0.5">M</span>}
            </div>
          ))}
        </div>
      )}

      {/* VSCODE-WEB section */}
      <div className="mt-1">
        <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: '0.5px', textTransform: 'uppercase', opacity: 0.5, padding: '4px 16px' }}>
          Vscode-Web
        </div>
      </div>

      {/* File tree */}
      <div className="flex-1 overflow-auto">
        {root.map((node) => (
          <FileTreeNode
            key={node.id}
            node={node}
            depth={0}
            selectedId={selectedNodeId}
            expandedIds={expandedIds}
            onToggle={handleToggle}
            onSelect={handleSelect}
          />
        ))}
      </div>
    </div>
  );
}
