import { useFileSystemStore, type FileNode } from './fileSystemStore';

const BASE = '/home/user/workspace';

function stripBase(absPath: string): string {
  if (absPath === BASE) return '';
  if (absPath.startsWith(BASE + '/')) return absPath.slice(BASE.length + 1);
  return absPath;
}

function toRel(absPath: string): string {
  const stripped = stripBase(absPath);
  return stripped;
}

export const workspaceStore = {
  getContent(absPath: string): string | undefined {
    const rel = toRel(absPath);
    if (!rel) {
      // Root level - return undefined (it's a dir)
      return undefined;
    }
    const state = useFileSystemStore.getState();
    const node = state.findNodeByPath(rel);
    if (node?.type === 'file') return node.content;
    return undefined;
  },

  listDir(absPath: string): string[] {
    const rel = toRel(absPath);
    const state = useFileSystemStore.getState();
    if (!rel) {
      // Root: return top-level nodes
      return state.root.map(n => n.name);
    }
    const node = state.findNodeByPath(rel);
    if (node?.type === 'folder' && node.children) {
      return node.children.map(c => c.name);
    }
    return [];
  },

  hasDir(absPath: string): boolean {
    const rel = toRel(absPath);
    if (!rel) return true; // root is always a dir
    const state = useFileSystemStore.getState();
    const node = state.findNodeByPath(rel);
    return node?.type === 'folder';
  },

  hasFile(absPath: string): boolean {
    const rel = toRel(absPath);
    if (!rel) return false;
    const state = useFileSystemStore.getState();
    const node = state.findNodeByPath(rel);
    return node?.type === 'file';
  },

  getMeta(absPath: string): { isDir: boolean; size: number; date: string } | null {
    const rel = toRel(absPath);
    if (!rel) return { isDir: true, size: 4096, date: 'Jan 15 10:00' };
    const state = useFileSystemStore.getState();
    const node = state.findNodeByPath(rel);
    if (!node) return null;
    const isDir = node.type === 'folder';
    const size = isDir ? 4096 : (node.content?.length || 0);
    return { isDir, size, date: 'Jan 15 10:00' };
  },

  setContent(absPath: string, content: string): void {
    const rel = toRel(absPath);
    if (!rel) return;
    const state = useFileSystemStore.getState();
    const existing = state.findNodeByPath(rel);
    if (existing) {
      // Update existing file content
      const newRoot = updateNodeContent(state.root, existing.id, content);
      useFileSystemStore.setState({ root: newRoot });
    } else {
      // Create new file - find parent folder
      const parts = rel.split('/');
      const fileName = parts.pop()!;
      const parentRel = parts.join('/');
      let parentId: string;
      if (!parentRel) {
        // Root level
        const rootNode = state.root[0];
        parentId = rootNode?.id || 'folder-src';
      } else {
        const parentNode = state.findNodeByPath(parentRel);
        if (parentNode) {
          parentId = parentNode.id;
        } else {
          // Create parent folders as needed
          parentId = 'folder-src';
        }
      }
      state.createFile(parentId, fileName, content);
    }
  },
};

function updateNodeContent(nodes: FileNode[], id: string, content: string): FileNode[] {
  return nodes.map(n => {
    if (n.id === id) return { ...n, content };
    if (n.children) return { ...n, children: updateNodeContent(n.children, id, content) };
    return n;
  });
}
