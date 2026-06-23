import { ChevronRightIcon, ChevronDownIcon, FolderIcon, FolderOpenIcon, FileIcon } from '@/components/builder/icons';

interface FileNode {
  id: string;
  name: string;
  type: 'file' | 'folder';
  path: string;
  content?: string;
  language?: string;
  isOpen?: boolean;
  children?: FileNode[];
}

interface Props {
  node: FileNode;
  depth?: number;
  selectedId?: string | null;
  expandedIds: Set<string>;
  onToggle: (node: FileNode) => void;
  onSelect: (node: FileNode) => void;
}

export function FileTreeNode({ node, depth = 0, selectedId, expandedIds, onToggle, onSelect }: Props) {
  const isExpanded = expandedIds.has(node.id);
  const isSelected = selectedId === node.id;
  const paddingLeft = 8 + depth * 12;

  if (node.type === 'folder') {
    return (
      <div>
        <div
          className="flex items-center gap-1 py-0.5 pr-2 cursor-pointer hover:bg-[var(--vscode-list-hover)] select-none text-[var(--vscode-fg)]"
          style={{ paddingLeft, fontSize: 13, fontWeight: 400 }}
          onClick={() => onToggle(node)}
        >
          <span className="w-4 h-4 flex items-center justify-center opacity-70">
            {isExpanded ? <ChevronDownIcon size={12} /> : <ChevronRightIcon size={12} />}
          </span>
          <span className="w-4 h-4 flex items-center justify-center mr-1">
            {isExpanded ? <FolderOpenIcon size={16} className="text-[#dcb67a]" /> : <FolderIcon size={16} className="text-[#dcb67a]" />}
          </span>
          <span className="truncate">{node.name}</span>
        </div>
        {isExpanded && node.children?.map(child => (
          <FileTreeNode key={child.id} node={child} depth={depth + 1}
            selectedId={selectedId} expandedIds={expandedIds}
            onToggle={onToggle} onSelect={onSelect} />
        ))}
      </div>
    );
  }

  const ext = node.name.split('.').pop() || '';
  const iconColors: Record<string, string> = {
    js: '#f4d03f', jsx: '#61dafb', ts: '#3178c6', tsx: '#61dafb',
    json: '#f4d03f', css: '#2965f1', html: '#e44d26', py: '#3776ab',
    go: '#00add8', rs: '#dea584', java: '#b07219', cpp: '#f34b7d',
    md: '#083fa1', yaml: '#cb171e', sql: '#e38c00', sh: '#89e051',
    vue: '#41b883', dockerfile: '#2496ed',
  };
  const iconColor = iconColors[ext] || 'var(--vscode-fg)';

  return (
    <div
      className={`flex items-center gap-1 py-0.5 pr-2 cursor-pointer select-none text-[var(--vscode-fg)] ${
        isSelected ? 'bg-[var(--vscode-list-active)]' : 'hover:bg-[var(--vscode-list-hover)]'
      }`}
      style={{ paddingLeft: paddingLeft + 16, fontSize: 13, fontWeight: 400 }}
      onClick={() => onSelect(node)}
    >
      <span className="w-4 h-4 flex items-center justify-center mr-1" style={{ color: iconColor }}>
        <FileIcon size={16} />
      </span>
      <span className="truncate">{node.name}</span>
    </div>
  );
}
