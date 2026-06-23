import { create } from 'zustand';

export interface FileNode {
  id: string;
  name: string;
  type: 'file' | 'folder';
  path: string;
  content?: string;
  language?: string;
  isOpen?: boolean;
  children?: FileNode[];
  parentId?: string | null;
}

interface FileSystemState {
  root: FileNode[];
  activeFilePath: string | null;
  expandedFolders: Set<string>;
  selectedNodeId: string | null;
  createFile: (parentId: string, name: string, content?: string) => void;
  createFolder: (parentId: string, name: string) => void;
  deleteNode: (id: string) => void;
  renameNode: (id: string, newName: string) => void;
  toggleFolder: (id: string) => void;
  moveNode: (id: string, newParentId: string) => void;
  setActiveFile: (path: string | null) => void;
  setSelectedNode: (id: string | null) => void;
  findNode: (id: string) => FileNode | undefined;
  findNodeByPath: (path: string) => FileNode | undefined;
  setRoot: (root: FileNode[]) => void;
  expandFolder: (id: string) => void;
  collapseFolder: (id: string) => void;
}

function generateId(): string {
  return `node-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
}

function findNodeRecursive(nodes: FileNode[], id: string): FileNode | undefined {
  for (const node of nodes) {
    if (node.id === id) return node;
    if (node.children) {
      const found = findNodeRecursive(node.children, id);
      if (found) return found;
    }
  }
  return undefined;
}

function findNodeByPathRecursive(nodes: FileNode[], path: string): FileNode | undefined {
  for (const node of nodes) {
    if (node.path === path) return node;
    if (node.children) {
      const found = findNodeByPathRecursive(node.children, path);
      if (found) return found;
    }
  }
  return undefined;
}

function removeNodeRecursive(nodes: FileNode[], id: string): FileNode[] {
  return nodes.filter((n) => n.id !== id).map((n) => {
    if (n.children) {
      return { ...n, children: removeNodeRecursive(n.children, id) };
    }
    return n;
  });
}

function updateNodeRecursive(nodes: FileNode[], id: string, updater: (n: FileNode) => FileNode): FileNode[] {
  return nodes.map((n) => {
    if (n.id === id) return updater(n);
    if (n.children) {
      return { ...n, children: updateNodeRecursive(n.children, id, updater) };
    }
    return n;
  });
}

function insertIntoFolder(nodes: FileNode[], parentId: string, newNode: FileNode): FileNode[] {
  return nodes.map((n) => {
    if (n.id === parentId && n.type === 'folder') {
      return { ...n, children: [...(n.children || []), newNode], isOpen: true };
    }
    if (n.children) {
      return { ...n, children: insertIntoFolder(n.children, parentId, newNode) };
    }
    return n;
  });
}

export const useFileSystemStore = create<FileSystemState>((set, get) => ({
  root: [],
  activeFilePath: null,
  expandedFolders: new Set<string>(),
  selectedNodeId: null,

  createFile: (parentId, name, content = '') => {
    const parent = get().findNode(parentId);
    const parentPath = parent?.path || '';
    const newNode: FileNode = {
      id: generateId(),
      name,
      type: 'file',
      path: parentPath ? `${parentPath}/${name}` : name,
      content,
      parentId,
    };
    set({ root: insertIntoFolder(get().root, parentId, newNode) });
  },

  createFolder: (parentId, name) => {
    const parent = get().findNode(parentId);
    const parentPath = parent?.path || '';
    const newNode: FileNode = {
      id: generateId(),
      name,
      type: 'folder',
      path: parentPath ? `${parentPath}/${name}` : name,
      children: [],
      isOpen: false,
      parentId,
    };
    set({ root: insertIntoFolder(get().root, parentId, newNode) });
  },

  deleteNode: (id) => {
    set({ root: removeNodeRecursive(get().root, id) });
  },

  renameNode: (id, newName) => {
    set({
      root: updateNodeRecursive(get().root, id, (n) => {
        const parentPath = n.path.split('/').slice(0, -1).join('/');
        return {
          ...n,
          name: newName,
          path: parentPath ? `${parentPath}/${newName}` : newName,
        };
      }),
    });
  },

  toggleFolder: (id) => {
    const expanded = new Set(get().expandedFolders);
    if (expanded.has(id)) {
      expanded.delete(id);
    } else {
      expanded.add(id);
    }
    set({
      expandedFolders: expanded,
      root: updateNodeRecursive(get().root, id, (n) => ({ ...n, isOpen: !n.isOpen })),
    });
  },

  moveNode: (id, newParentId) => {
    const node = get().findNode(id);
    if (!node) return;
    const newRoot = removeNodeRecursive(get().root, id);
    const movedNode = { ...node, parentId: newParentId };
    set({ root: insertIntoFolder(newRoot, newParentId, movedNode) });
  },

  setActiveFile: (path) => set({ activeFilePath: path }),
  setSelectedNode: (id) => set({ selectedNodeId: id }),

  findNode: (id) => findNodeRecursive(get().root, id),
  findNodeByPath: (path) => findNodeByPathRecursive(get().root, path),

  setRoot: (root) => set({ root }),

  expandFolder: (id) => {
    const expanded = new Set(get().expandedFolders);
    expanded.add(id);
    set({
      expandedFolders: expanded,
      root: updateNodeRecursive(get().root, id, (n) => ({ ...n, isOpen: true })),
    });
  },

  collapseFolder: (id) => {
    const expanded = new Set(get().expandedFolders);
    expanded.delete(id);
    set({
      expandedFolders: expanded,
      root: updateNodeRecursive(get().root, id, (n) => ({ ...n, isOpen: false })),
    });
  },
}));
