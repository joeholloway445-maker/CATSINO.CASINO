import { useRef, useState, useCallback } from 'react';
import { useSidebarStore } from '@/lib/builder/store/sidebarStore';
import { ExplorerView } from '@/components/builder/sidebar/ExplorerView';
import { SearchView } from '@/components/builder/sidebar/SearchView';
import { SCMView } from '@/components/builder/sidebar/SCMView';
import { RunDebugView } from '@/components/builder/sidebar/RunDebugView';
import { ExtensionsView } from '@/components/builder/sidebar/ExtensionsView';

export function Sidebar() {
  const { isVisible, width, setWidth, activeView } = useSidebarStore();
  const sidebarRef = useRef<HTMLDivElement>(null);
  const [isResizing, setIsResizing] = useState(false);

  const handleMouseDown = useCallback((e: React.MouseEvent) => {
    e.preventDefault();
    setIsResizing(true);
    const startX = e.clientX;
    const startWidth = width;

    const handleMouseMove = (moveEvent: MouseEvent) => {
      const newWidth = startWidth + (moveEvent.clientX - startX);
      setWidth(newWidth);
    };

    const handleMouseUp = () => {
      setIsResizing(false);
      document.removeEventListener('mousemove', handleMouseMove);
      document.removeEventListener('mouseup', handleMouseUp);
    };

    document.addEventListener('mousemove', handleMouseMove);
    document.addEventListener('mouseup', handleMouseUp);
  }, [width, setWidth]);

  if (!isVisible) return null;

  return (
    <div
      ref={sidebarRef}
      style={{
        width,
        backgroundColor: 'var(--vscode-sidebar-bg)',
        display: 'flex',
        flexDirection: 'column',
        flexShrink: 0,
        position: 'relative',
        userSelect: 'none',
      }}
    >
      {/* Sidebar content */}
      <div style={{ flex: 1, overflow: 'auto' }}>
        {activeView === 'explorer' && <ExplorerView />}
        {activeView === 'search' && <SearchView />}
        {activeView === 'scm' && <SCMView />}
        {activeView === 'run' && <RunDebugView />}
        {activeView === 'extensions' && <ExtensionsView />}
      </div>

      {/* Resize sash */}
      <div
        onMouseDown={handleMouseDown}
        style={{
          position: 'absolute',
          right: 0,
          top: 0,
          bottom: 0,
          width: 4,
          cursor: 'col-resize',
          zIndex: 10,
          backgroundColor: isResizing ? 'var(--vscode-sash-hover)' : 'transparent',
        }}
      />
    </div>
  );
}
