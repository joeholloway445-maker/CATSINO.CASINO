import type { FileNode } from '@/lib/builder/store/fileSystemStore';

const appTsx = `import { useState, useCallback } from 'react';
import { Button } from './components/Button';
import { Header } from './components/Header';
import { formatDate, generateId } from './utils/helpers';
import type { User, AppConfig } from './types';

const config: AppConfig = {
  appName: 'MyApp',
  version: '1.0.0',
  apiUrl: 'https://api.example.com',
  features: {
    darkMode: true,
    notifications: true,
    analytics: false,
  },
};

const defaultUser: User = {
  id: generateId('user'),
  name: 'Jane Developer',
  email: 'jane@example.com',
  role: 'admin',
  createdAt: new Date(),
};

export default function App() {
  const [count, setCount] = useState(0);
  const [user, setUser] = useState<User>(defaultUser);

  const handleIncrement = useCallback(() => {
    setCount((prev) => prev + 1);
  }, []);

  const handleReset = useCallback(() => {
    setCount(0);
  }, []);

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <Header title={config.appName} user={user} />
      <main className="container mx-auto px-4 py-8">
        <h1 className="text-3xl font-bold mb-4">
          Welcome to {config.appName}
        </h1>
        <p className="text-gray-600 dark:text-gray-300 mb-6">
          Version {config.version} — Built with React + TypeScript
        </p>
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6 mb-6">
          <h2 className="text-xl font-semibold mb-4">Counter Demo</h2>
          <p className="text-2xl font-mono mb-4">Count: {count}</p>
          <div className="flex gap-3">
            <Button onClick={handleIncrement} variant="primary">
              Increment
            </Button>
            <Button onClick={handleReset} variant="secondary">
              Reset
            </Button>
          </div>
        </div>
        <footer className="text-sm text-gray-500 mt-8">
          Last updated: {formatDate(new Date())}
        </footer>
      </main>
    </div>
  );
}
`;

const mainTsx = `import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import './index.css';

const rootElement = document.getElementById('root');
if (!rootElement) {
  throw new Error('Failed to find root element');
}

createRoot(rootElement).render(
  <StrictMode>
    <App />
  </StrictMode>
);
`;

const indexCss = `@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --color-primary: #3b82f6;
    --color-secondary: #64748b;
    --color-success: #22c55e;
    --color-danger: #ef4444;
  }

  body {
    @apply antialiased text-gray-900 dark:text-gray-100;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  }
}

@layer components {
  .btn {
    @apply px-4 py-2 rounded-md font-medium transition-colors;
  }

  .btn-primary {
    @apply btn bg-blue-600 text-white hover:bg-blue-700;
  }

  .card {
    @apply bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700;
  }
}
`;

const buttonTsx = `import type { ReactNode, ButtonHTMLAttributes } from 'react';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  children: ReactNode;
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
}

export function Button({
  children,
  variant = 'primary',
  size = 'md',
  className = '',
  ...props
}: ButtonProps) {
  const baseStyles = 'inline-flex items-center justify-center rounded-md font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed';

  const variantStyles = {
    primary: 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500',
    secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300 focus:ring-gray-500',
    danger: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500',
    ghost: 'text-gray-700 hover:bg-gray-100 focus:ring-gray-500',
  };

  const sizeStyles = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg',
  };

  return (
    <button
      className={\`\${baseStyles} \${variantStyles[variant]} \${sizeStyles[size]} \${className}\`}
      {...props}
    >
      {children}
    </button>
  );
}
`;

const headerTsx = `import { useState } from 'react';
import type { User } from '../types';

interface HeaderProps {
  title: string;
  user: User;
}

export function Header({ title, user }: HeaderProps) {
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <header className="bg-white dark:bg-gray-900 border-b border-gray-200 dark:border-gray-700">
      <div className="container mx-auto px-4 h-16 flex items-center justify-between">
        <h1 className="text-xl font-bold text-gray-900 dark:text-white">
          {title}
        </h1>
        <div className="relative">
          <button
            onClick={() => setMenuOpen(!menuOpen)}
            className="flex items-center gap-2 text-sm text-gray-700 dark:text-gray-300 hover:text-gray-900"
          >
            <span className="w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center text-white font-medium">
              {user.name.charAt(0)}
            </span>
            <span>{user.name}</span>
          </button>
          {menuOpen && (
            <div className="absolute right-0 mt-2 w-48 bg-white dark:bg-gray-800 rounded-md shadow-lg border border-gray-200 dark:border-gray-700 py-1">
              <a href="#profile" className="block px-4 py-2 text-sm hover:bg-gray-100 dark:hover:bg-gray-700">
                Profile
              </a>
              <a href="#settings" className="block px-4 py-2 text-sm hover:bg-gray-100 dark:hover:bg-gray-700">
                Settings
              </a>
              <hr className="my-1 border-gray-200 dark:border-gray-700" />
              <a href="#logout" className="block px-4 py-2 text-sm text-red-600 hover:bg-gray-100 dark:hover:bg-gray-700">
                Sign out
              </a>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
`;

const helpersTs = `/**
 * Format a Date object to a locale date string
 */
export function formatDate(date: Date): string {
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

/**
 * Generate a unique ID with optional prefix
 */
export function generateId(prefix: string = 'id'): string {
  return \`\${prefix}-\${Date.now()}-\${Math.random().toString(36).slice(2, 7)}\`;
}

/**
 * Deep clone an object using JSON serialization
 */
export function deepClone<T>(obj: T): T {
  return JSON.parse(JSON.stringify(obj));
}

/**
 * Debounce a function call
 */
export function debounce<T extends (...args: unknown[]) => void>(
  fn: T,
  delay: number
): (...args: Parameters<T>) => void {
  let timer: ReturnType<typeof setTimeout>;
  return (...args: Parameters<T>) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), delay);
  };
}

/**
 * Capitalize first letter of a string
 */
export function capitalize(str: string): string {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

/**
 * Truncate text with ellipsis
 */
export function truncate(str: string, maxLength: number): string {
  if (str.length <= maxLength) return str;
  return str.slice(0, maxLength - 3) + '...';
}
`;

const typesTs = `/**
 * User role types
 */
export type UserRole = 'admin' | 'editor' | 'viewer';

/**
 * User interface
 */
export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  avatar?: string;
  createdAt: Date;
}

/**
 * Feature flags
 */
export interface FeatureFlags {
  darkMode: boolean;
  notifications: boolean;
  analytics: boolean;
  betaFeatures?: boolean;
}

/**
 * App configuration
 */
export interface AppConfig {
  appName: string;
  version: string;
  apiUrl: string;
  features: FeatureFlags;
}

/**
 * API Response wrapper
 */
export interface ApiResponse<T> {
  data: T;
  status: number;
  message?: string;
}

/**
 * Paginated result
 */
export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}
`;

const indexHtml = `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>React + TypeScript App</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
`;

const packageJson = `{
  "name": "my-react-app",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.21.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.43",
    "@types/react-dom": "^18.2.17",
    "@typescript-eslint/eslint-plugin": "^6.14.0",
    "@typescript-eslint/parser": "^6.14.0",
    "@vitejs/plugin-react": "^4.2.1",
    "autoprefixer": "^10.4.16",
    "eslint": "^8.55.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.5",
    "postcss": "^8.4.32",
    "tailwindcss": "^3.4.0",
    "typescript": "^5.2.2",
    "vite": "^5.0.8"
  }
}
`;

const tsconfigJson = `{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
`;

const viteConfigTs = `import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    open: true,
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
});
`;

const readmeMd = `# My React App

A modern React application built with TypeScript, Vite, and Tailwind CSS.

## Features

- React 18 with hooks and functional components
- TypeScript for type safety
- Tailwind CSS for styling
- Vite for fast development and building
- Path aliases with \\"@/\\" prefix
- ESLint for code quality

## Getting Started

### Prerequisites

- Node.js 18 or higher
- npm or yarn

### Installation

\`\`\`bash
npm install
\`\`\`

### Development

\`\`\`bash
npm run dev
\`\`\`

The app will be available at [http://localhost:3000](http://localhost:3000).

### Build

\`\`\`bash
npm run build
\`\`\`

### Lint

\`\`\`bash
npm run lint
\`\`\`

## Project Structure

\`\`\`
src/
  components/     # Reusable UI components
  utils/          # Utility functions
  types/          # TypeScript interfaces
  App.tsx         # Root application component
  main.tsx        # Application entry point
  index.css       # Global styles and Tailwind directives
\`\`\`

## Scripts

| Script | Description |
|--------|-------------|
| \`dev\` | Start development server |
| \`build\` | Build for production |
| \`preview\` | Preview production build |
| \`lint\` | Run ESLint |
| \`typecheck\` | Run TypeScript type checker |

## License

MIT
`;

const gitignore = `# Dependencies
node_modules/
.pnp
.pnp.js

# Build
dist/
dist-ssr/
*.local

# Editor
.vscode/*
!.vscode/extensions.json
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
lerna-debug.log*

# Environment
.env
.env.local
.env.*.local

# Testing
coverage/
`;

export function createDemoWorkspace(): FileNode[] {
  return [
    {
      id: 'folder-src',
      name: 'src',
      type: 'folder',
      path: 'src',
      isOpen: true,
      children: [
        {
          id: 'file-app-tsx',
          name: 'App.tsx',
          type: 'file',
          path: 'src/App.tsx',
          content: appTsx,
          language: 'typescriptreact',
          parentId: 'folder-src',
        },
        {
          id: 'file-main-tsx',
          name: 'main.tsx',
          type: 'file',
          path: 'src/main.tsx',
          content: mainTsx,
          language: 'typescriptreact',
          parentId: 'folder-src',
        },
        {
          id: 'file-index-css',
          name: 'index.css',
          type: 'file',
          path: 'src/index.css',
          content: indexCss,
          language: 'css',
          parentId: 'folder-src',
        },
        {
          id: 'folder-components',
          name: 'components',
          type: 'folder',
          path: 'src/components',
          isOpen: true,
          children: [
            {
              id: 'file-button-tsx',
              name: 'Button.tsx',
              type: 'file',
              path: 'src/components/Button.tsx',
              content: buttonTsx,
              language: 'typescriptreact',
              parentId: 'folder-components',
            },
            {
              id: 'file-header-tsx',
              name: 'Header.tsx',
              type: 'file',
              path: 'src/components/Header.tsx',
              content: headerTsx,
              language: 'typescriptreact',
              parentId: 'folder-components',
            },
          ],
          parentId: 'folder-src',
        },
        {
          id: 'folder-utils',
          name: 'utils',
          type: 'folder',
          path: 'src/utils',
          isOpen: true,
          children: [
            {
              id: 'file-helpers-ts',
              name: 'helpers.ts',
              type: 'file',
              path: 'src/utils/helpers.ts',
              content: helpersTs,
              language: 'typescript',
              parentId: 'folder-utils',
            },
          ],
          parentId: 'folder-src',
        },
        {
          id: 'folder-types',
          name: 'types',
          type: 'folder',
          path: 'src/types',
          isOpen: true,
          children: [
            {
              id: 'file-types-index',
              name: 'index.ts',
              type: 'file',
              path: 'src/types/index.ts',
              content: typesTs,
              language: 'typescript',
              parentId: 'folder-types',
            },
          ],
          parentId: 'folder-src',
        },
      ],
    },
    {
      id: 'folder-public',
      name: 'public',
      type: 'folder',
      path: 'public',
      isOpen: false,
      children: [
        {
          id: 'file-index-html',
          name: 'index.html',
          type: 'file',
          path: 'public/index.html',
          content: indexHtml,
          language: 'html',
          parentId: 'folder-public',
        },
      ],
    },
    {
      id: 'file-package-json',
      name: 'package.json',
      type: 'file',
      path: 'package.json',
      content: packageJson,
      language: 'json',
    },
    {
      id: 'file-tsconfig-json',
      name: 'tsconfig.json',
      type: 'file',
      path: 'tsconfig.json',
      content: tsconfigJson,
      language: 'json',
    },
    {
      id: 'file-vite-config',
      name: 'vite.config.ts',
      type: 'file',
      path: 'vite.config.ts',
      content: viteConfigTs,
      language: 'typescript',
    },
    {
      id: 'file-readme',
      name: 'README.md',
      type: 'file',
      path: 'README.md',
      content: readmeMd,
      language: 'markdown',
    },
    {
      id: 'file-gitignore',
      name: '.gitignore',
      type: 'file',
      path: '.gitignore',
      content: gitignore,
      language: 'plaintext',
    },
  ];
}
