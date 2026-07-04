export interface Extension {
  id: string;
  name: string;
  publisher: string;
  description: string;
  version: string;
  rating: number;
  downloads: string;
  iconColor: string;
  installed?: boolean;
  enabled?: boolean;
  isFunctional?: boolean;
  readme: string;
  features: string[];
  changelog: { version: string; date: string; notes: string }[];
}

export const extensions: Extension[] = [
  // ==========================================
  // 10 DETAILED EXTENSIONS
  // ==========================================

  {
    id: 'prettier',
    name: 'Prettier - Code: formatter',
    publisher: 'Prettier',
    description: 'Code: formatter for VS Code:',
    version: '3.2.5',
    rating: 4.5,
    downloads: '45.2M',
    iconColor: '#56b3b4',
    isFunctional: true,
    installed: true,
    enabled: true,
    readme: `# Prettier - Code: formatter

## Quick Start
Install this extension, open a JS/TS/CSS/HTML file, and press Shift+Alt+F to format the entire document. Prettier will automatically detect your configuration and apply consistent formatting.

## Settings
- prettier.printWidth: 80
- prettier.tabWidth: 2
- prettier.useTabs: false
- prettier.semi: true
- prettier.singleQuote: false
- prettier.trailingComma: 'es5'
- prettier.bracketSpacing: true
- prettier.arrowParens: 'always'

## Requirements
VS Code: 1.60+. No additional dependencies required. Supports formatting via the Format Document command or format-on-save.`,
    features: [
      'Format on save — automatically format when you save',
      'Format selection — format only the selected code',
      'Support for 20+ languages including JS, TS, CSS, HTML, JSON, Markdown',
      'Customizable via .prettierrc configuration file',
      'Integration with ESLint for combined formatting and linting',
      'Ignore specific files with .prettierignore',
    ],
    changelog: [
      { version: '3.2.5', date: '2024-01-10', notes: 'Fixed TypeScript formatting with decorators. Improved range formatting performance.' },
      { version: '3.2.0', date: '2023-12-05', notes: 'Added support for new CSS features. Updated parser dependencies.' },
      { version: '3.1.0', date: '2023-10-20', notes: 'Improved JSON formatting stability. Fixed arrow function formatting edge cases.' },
      { version: '3.0.0', date: '2023-09-01', notes: 'Major release with new formatting engine. Breaking changes to plugin API.' },
    ],
  },

  {
    id: 'eslint',
    name: 'ESLint',
    publisher: 'Microsoft',
    description: 'Integrates ESLint JavaScript',
    version: '2.4.4',
    rating: 4.3,
    downloads: '32.1M',
    iconColor: '#4b32c3',
    isFunctional: true,
    installed: true,
    enabled: true,
    readme: `# ESLint

## Quick Start
Open a JavaScript or TypeScript file. ESLint will automatically lint your code and show diagnostics in the Problems panel. Use the Quick Fix menu (Ctrl+.) to auto-fix issues.

## Settings
- eslint.enable: true
- eslint.format.enable: false
- eslint.codeActionsOnSave.mode: 'all'
- eslint.workingDirectories: []
- eslint.validate: ['javascript', 'typescript']

## Requirements
VS Code: 1.75+. ESLint npm package 7.0+ installed locally or globally. Supports flat config (eslint.config.js) and legacy .eslintrc formats.`,
    features: [
      'Real-time linting with diagnostic messages in the editor',
      'Auto-fix on save with configurable fix mode',
      'Support for JavaScript, TypeScript, JSX, TSX, Vue, and JSON',
      'Flat config (eslint.config.js) and legacy .eslintrc support',
      'Quick Fix code actions via Ctrl+. menu',
      'Customizable working directories for monorepo setups',
    ],
    changelog: [
      { version: '2.4.4', date: '2024-01-12', notes: 'Fixed memory leak in long-running sessions. Improved flat config resolution.' },
      { version: '2.4.0', date: '2023-11-20', notes: 'Added support for ESLint 9.x flat config by default. Improved TypeScript resolution.' },
      { version: '2.3.0', date: '2023-09-15', notes: 'New experimental formatter integration. Better handling of ignored files.' },
      { version: '2.2.0', date: '2023-07-01', notes: 'Improved performance for large codebases. Added support for custom ESLint API.' },
    ],
  },

  {
    id: 'gitlens',
    name: 'GitLens',
    publisher: 'GitKraken',
    description: 'Supercharge Git within VS Code:',
    version: '14.8.0',
    rating: 4.8,
    downloads: '28.7M',
    iconColor: '#f14c4c',
    isFunctional: true,
    readme: `# GitLens

## Quick Start
Open any file in a Git repository. GitLens automatically adds inline blame annotations, hover information, and a rich sidebar with commit history.

## Settings
- gitlens.currentLine.enabled: true
- gitlens.hovers.enabled: true
- gitlens.codeLens.enabled: true
- gitlens.views.repositories.enabled: true

## Requirements
VS Code: 1.80+. Git 2.7+ must be installed. Works with local and remote repositories.`,
    features: [
      'Inline blame annotations showing who last modified each line',
      'Interactive commit graph with branch visualization',
      'Branch and tag comparison with diff views',
      'Rich hover tooltips with commit details and history',
      'Stashes, remotes, and contributors views in the sidebar',
      'Commit search by message, author, or file',
    ],
    changelog: [
      { version: '14.8.0', date: '2024-01-08', notes: 'Added AI-generated commit messages. Improved graph performance for large repos.' },
      { version: '14.7.0', date: '2023-12-01', notes: 'New focus mode for commit graph. Enhanced worktree support.' },
      { version: '14.6.0', date: '2023-10-25', notes: 'Added patch rebase support. Improved deep link navigation.' },
      { version: '14.5.0', date: '2023-09-10', notes: 'New Launchpad feature for PR reviews. Better integration with GitKraken Desktop.' },
    ],
  },

  {
    id: 'live-server',
    name: 'Live Server',
    publisher: 'Ritwick Dey',
    description: 'Launch a development local server',
    version: '5.7.9',
    rating: 4.4,
    downloads: '35.4M',
    iconColor: '#4CAF50',
    isFunctional: true,
    readme: `# Live Server

## Quick Start
Open an HTML file and click "Go Live" in the status bar. A local development server will start and your default browser will open with live reload enabled.

## Settings
- liveServer.settings.port: 5500
- liveServer.settings.root: '/'
- liveServer.settings.CustomBrowser: 'chrome'
- liveServer.settings.https: false
- liveServer.settings.proxy: {}

## Requirements
VS Code: 1.50+. No additional dependencies. Supports HTML, CSS, and JavaScript files out of the box.`,
    features: [
      'One-click launch with "Go Live" status bar button',
      'Live reload — browser refreshes automatically on file save',
      'Customizable port and root directory',
      'Proxy support for API forwarding during development',
      'HTTPS support for secure local testing',
      'Multi-root workspace support',
    ],
    changelog: [
      { version: '5.7.9', date: '2023-12-15', notes: 'Fixed WebSocket connection issue on Windows. Improved error handling for port conflicts.' },
      { version: '5.7.5', date: '2023-08-20', notes: 'Added support for custom MIME types. Improved startup performance.' },
      { version: '5.7.0', date: '2023-05-10', notes: 'New ignore file patterns. Better handling of large file changes.' },
      { version: '5.6.0', date: '2023-02-01', notes: 'Added CSS injection without full page reload. Improved stability.' },
    ],
  },

  {
    id: 'python',
    name: 'Python',
    publisher: 'Microsoft',
    description: 'IntelliSense, linting, debugging',
    version: '2024.2.1',
    rating: 4.6,
    downloads: '52.1M',
    iconColor: '#3776ab',
    isFunctional: true,
    readme: `# Python

## Quick Start
Open a .py file. The extension automatically activates and provides IntelliSense, linting, and debugging support. Select a Python interpreter via the status bar.

## Settings
- python.defaultInterpreterPath: 'python'
- python.linting.enabled: true
- python.formatting.provider: 'black'
- python.analysis.typeCheckingMode: 'basic'

## Requirements
VS Code: 1.85+. Python 3.7+ recommended. Optional: Pylance for enhanced IntelliSense, Black for formatting, debugpy for debugging.`,
    features: [
      'IntelliSense with Pylance for type-aware code completion',
      'Integrated debugging with breakpoints and variable inspection',
      'Jupyter notebook support with interactive cells',
      'Virtual environment detection and management',
      'Linting with Pylint, Flake8, or Ruff',
      'Refactoring tools including rename and extract method',
    ],
    changelog: [
      { version: '2024.2.1', date: '2024-01-20', notes: 'Improved Django template debugging. Fixed Python 3.13 compatibility issues.' },
      { version: '2024.0.0', date: '2023-12-01', notes: 'New test explorer with pytest improvements. Added Hatch environment support.' },
      { version: '2023.20.0', date: '2023-10-15', notes: 'Improved IntelliSpeed for large monorepos. Better Ruff integration.' },
      { version: '2023.18.0', date: '2023-09-01', notes: 'New create environment command. Enhanced Jupyter kernel management.' },
    ],
  },

  {
    id: 'docker',
    name: 'Docker',
    publisher: 'Microsoft',
    description: 'Makes it easy to create, manage, debug containers',
    version: '1.29.0',
    rating: 4.5,
    downloads: '28.3M',
    iconColor: '#2496ed',
    isFunctional: true,
    readme: `# Docker

## Quick Start
Open a folder with a Dockerfile or docker-compose.yml. The Docker panel shows containers, images, and registries. Right-click a Dockerfile to build an image.

## Settings
- docker.containers.groupBy: 'ImageName'
- docker.images.groupBy: 'Repository'
- docker.dockerfile.experimental: false

## Requirements
VS Code: 1.80+. Docker Desktop or Docker Engine must be installed. Docker Compose v2 for multi-container support.`,
    features: [
      'Container management — start, stop, inspect, and remove containers',
      'Image management with build, pull, push, and prune',
      'Dockerfile editing with IntelliSense and linting',
      'Docker Compose support for multi-container applications',
      'Container debugging with attach and launch configurations',
      'Registry explorer for Docker Hub and Azure Container Registry',
    ],
    changelog: [
      { version: '1.29.0', date: '2024-01-18', notes: 'Added AI-powered Dockerfile generation. Improved container log streaming.' },
      { version: '1.28.0', date: '2023-11-30', notes: 'New volume management UI. Better support for dev containers.' },
      { version: '1.27.0', date: '2023-10-10', notes: 'Improved compose file validation. Added health check visualization.' },
      { version: '1.26.0', date: '2023-08-22', notes: 'New container resource usage graphs. Fixed image layer inspection.' },
    ],
  },

  {
    id: 'rest-client',
    name: 'REST Client',
    publisher: 'Huachao Mao',
    description: 'REST Client for Visual Studio Code:',
    version: '0.25.1',
    rating: 4.6,
    downloads: '12.3M',
    iconColor: '#2196F3',
    isFunctional: true,
    readme: `# REST Client

## Quick Start
Create a .http or .rest file and write your request: GET https://api.example.com/users. Click "Send Request" above the request to see the response.

## Settings
- rest-client.defaultUserAgent: 'vscode-restclient'
- rest-client.timeoutinmilliseconds: 0
- rest-client.followredirect: true
- rest-client.environmentvariables: {}

## Requirements
VS Code: 1.70+. No external dependencies. Optionally configure environments for variable substitution across requests.`,
    features: [
      'Send HTTP requests directly from editor — GET, POST, PUT, DELETE, PATCH',
      'Environment variables for switching between dev, staging, and prod',
      'Rich response preview with syntax highlighting for JSON and XML',
      'cURL command generation from any request',
      'Request history and save-to-file support',
      'GraphQL query support with variables',
    ],
    changelog: [
      { version: '0.25.1', date: '2023-11-15', notes: 'Fixed OAuth2 token refresh issue. Improved multipart form data handling.' },
      { version: '0.25.0', date: '2023-08-01', notes: 'Added WebSocket request support. Improved response streaming.' },
      { version: '0.24.0', date: '2023-04-20', notes: 'New request folding in the sidebar. Better certificate handling.' },
      { version: '0.23.0', date: '2023-01-10', notes: 'Added gRPC support. Improved GraphQL introspection.' },
    ],
  },

  {
    id: 'material-icon',
    name: 'Material Icon Theme',
    publisher: 'Philipp Kief',
    description: 'Material Design Icons',
    version: '4.34.0',
    rating: 4.9,
    downloads: '35.6M',
    iconColor: '#00bcd4',
    readme: `# Material Icon Theme

## Quick Start
Install the extension, open the Command Palette (Ctrl+Shift+P), and run "File Icon Theme". Select "Material Icon Theme" to activate.

## Settings
- material-icon-theme.folders.color: '#90a4ae'
- material-icon-theme.folders.theme: 'specific'
- material-icon-theme.opacity: 1
- material-icon-theme.saturation: 1

## Requirements
VS Code: 1.55+. No additional dependencies. Works with all file types and folder structures.`,
    features: [
      '500+ file icons covering all popular programming languages',
      'Customizable folder icon colors and themes',
      'Adjustable icon opacity and saturation',
      'Auto-detects file associations by extension',
      'Custom icon associations via settings.json',
      'High-resolution icons for Retina displays',
    ],
    changelog: [
      { version: '4.34.0', date: '2024-01-05', notes: 'Added icons for Astro, Bun, and Terraform files. Updated folder icons.' },
      { version: '4.33.0', date: '2023-11-20', notes: 'New icon for Vite config files. Improved Deno and Edge icons.' },
      { version: '4.32.0', date: '2023-10-01', notes: 'Added SvelteKit folder icons. Updated Angular file icons.' },
      { version: '4.31.0', date: '2023-08-15', notes: 'New icon for Tailwind config. Improved React and TSX icons.' },
    ],
  },

  {
    id: 'tailwind',
    name: 'Tailwind CSS IntelliSense',
    publisher: 'Tailwind Labs',
    description: 'Intelligent Tailwind CSS tooling',
    version: '0.10.5',
    rating: 4.5,
    downloads: '8.2M',
    iconColor: '#38bdf8',
    isFunctional: true,
    readme: `# Tailwind CSS IntelliSense

## Quick Start
Open a project with Tailwind CSS configured. The extension reads your tailwind.config.js and provides intelligent completions for all utility classes.

## Settings
- tailwindCSS.includeLanguages: {}
- tailwindCSS.emmetCompletions: false
- tailwindCSS.classAttributes: ['class', 'className']
- tailwindCSS.experimental.configFile: null

## Requirements
VS Code: 1.72+. Tailwind CSS v2.0+ or v3.0+. The extension scans your workspace for tailwind.config files automatically.`,
    features: [
      'Autocomplete for all Tailwind utility classes with config awareness',
      'Hover preview showing generated CSS for any class',
      'Linting for invalid or deprecated class names',
      'Support for custom configuration files and plugins',
      'Class sorting with Prettier integration',
      'Arbitrary value completions for dynamic styling',
    ],
    changelog: [
      { version: '0.10.5', date: '2024-01-12', notes: 'Improved v3.4 support with new size utilities. Fixed parsing of dynamic class names.' },
      { version: '0.10.0', date: '2023-11-01', notes: 'Added @container query completions. Improved monorepo config resolution.' },
      { version: '0.9.0', date: '2023-09-20', notes: 'New class sorting integration. Better handling of CSS layers.' },
      { version: '0.8.0', date: '2023-07-15', notes: 'Added inline class extraction hints. Improved TypeScript support.' },
    ],
  },

  {
    id: 'copilot',
    name: 'GitHub Copilot',
    publisher: 'GitHub',
    description: 'AI pair programmer',
    version: '1.150.0',
    rating: 4.6,
    downloads: '28.1M',
    iconColor: '#2b2b2b',
    isFunctional: true,
    readme: `# GitHub Copilot

## Quick Start
Sign in with your GitHub account and start coding. Copilot suggests whole lines or blocks of code: as you type.

## Settings
- github.copilot.enable
- github.copilot.inlineSuggest.enable
- github.copilot.editor.enableAutoCompletions: true

## Requirements
VS Code: 1.70+, GitHub account with Copilot subscription.`,
    features: [
      'Inline code: suggestions as you type',
      'Chat interface for asking coding questions',
      'Multi-line completions for functions and classes',
      'Supports 30+ programming languages',
      'GitHub Copilot Chat for interactive AI assistance',
      'Test generation and code: explanation',
    ],
    changelog: [
      { version: '1.150.0', date: '2024-01-15', notes: 'Improved chat context awareness. New /test command for test generation.' },
      { version: '1.140.0', date: '2023-12-10', notes: 'Added support for custom instructions. Improved JavaScript completions.' },
      { version: '1.130.0', date: '2023-11-05', notes: 'Faster suggestion generation. Better handling of large files.' },
    ],
  },

  // ==========================================
  // 20 REMAINING EXTENSIONS (shorter content)
  // ==========================================

  {
    id: 'go',
    name: 'Go',
    publisher: 'Google',
    description: 'Rich Go language support',
    version: '0.41.0',
    rating: 4.4,
    downloads: '15.2M',
    iconColor: '#00add8',
    readme: `# Go

## Quick Start
Open a .go file. The extension activates automatically, providing IntelliSense, linting, and debugging. Install gopls for the best experience.

## Settings
- gopls.build.experimentalWorkspaceModule: true
- go.lintTool: 'golint'

## Requirements
VS Code: 1.75+. Go 1.18+. gopls language server recommended.`,
    features: [
      'IntelliSense powered by gopls language server',
      'Integrated debugging with Delve debugger',
      'Auto-imports and organize imports on save',
      'Run and test Go code: directly from the editor',
      'Generate interface implementations and unit tests',
    ],
    changelog: [
      { version: '0.41.0', date: '2024-01-08', notes: 'Improved generics support. Updated gopls integration for Go 1.21.' },
      { version: '0.40.0', date: '2023-11-15', notes: 'New test explorer integration. Better workspace symbol search.' },
      { version: '0.39.0', date: '2023-09-20', notes: 'Added fuzz test support. Improved error handling in the language server.' },
    ],
  },

  {
    id: 'rust-analyzer',
    name: 'rust-analyzer',
    publisher: 'rust-analyzer',
    description: 'Rust language support',
    version: '0.3.18',
    rating: 4.7,
    downloads: '4.8M',
    iconColor: '#dea584',
    readme: `# rust-analyzer

## Quick Start
Open a Rust project (Cargo.toml). rust-analyzer provides IDE features powered by the Rust compiler itself.

## Settings
- rust-analyzer.cargo.features: 'all'
- rust-analyzer.checkOnSave.command: 'clippy'

## Requirements
VS Code: 1.70+. Rust toolchain via rustup. Cargo for project management.`,
    features: [
      'Fast and accurate code: completion with type inference',
      'Inline type hints and parameter name hints',
      'Real-time error checking with cargo check integration',
      'Smart refactoring including rename and extract function',
      'Go to definition and find all references across crates',
    ],
    changelog: [
      { version: '0.3.18', date: '2024-01-10', notes: 'Improved trait resolution. Better proc-macro expansion support.' },
      { version: '0.3.15', date: '2023-11-22', notes: 'New signature help for generic functions. Faster indexing for large workspaces.' },
      { version: '0.3.12', date: '2023-09-30', notes: 'Added support for Rust 1.72 features. Improved macro debugging.' },
    ],
  },

  {
    id: 'es7-react',
    name: 'ES7+ React/Redux/GraphQL snippets',
    publisher: 'dsznajder',
    description: 'Extensions for React, Redux and GraphQL',
    version: '4.4.3',
    rating: 4.3,
    downloads: '22.5M',
    iconColor: '#61dafb',
    readme: `# ES7+ React/Redux/GraphQL snippets

## Quick Start
Type a prefix like rfc, rcc, or useState and press Tab to expand a snippet in any JS/TS file.

## Settings
No required settings. Customize snippet preferences in VS Code: settings.

## Requirements
VS Code: 1.60+. Works with JavaScript and TypeScript files.`,
    features: [
      '100+ snippets for React components (functional and class-based)',
      'Redux boilerplate snippets for actions, reducers, and store',
      'GraphQL query and mutation snippets',
      'React Hooks snippets (useState, useEffect, useContext, etc.)',
      'TypeScript-compatible snippets with type annotations',
    ],
    changelog: [
      { version: '4.4.3', date: '2023-12-01', notes: 'Added Next.js App Router snippets. Updated React 18 hook patterns.' },
      { version: '4.4.0', date: '2023-08-15', notes: 'New Server Component snippets. Improved TypeScript snippet accuracy.' },
      { version: '4.3.0', date: '2023-04-20', notes: 'Added Zustand state management snippets. Updated GraphQL templates.' },
    ],
  },

  {
    id: 'auto-rename',
    name: 'Auto Rename Tag',
    publisher: 'Jun Han',
    description: 'Auto rename paired HTML/XML tag',
    version: '0.1.10',
    rating: 4.2,
    downloads: '8.9M',
    iconColor: '#e44d26',
    readme: `# Auto Rename Tag

## Quick Start
Rename any HTML tag and the paired opening/closing tag updates automatically.

## Settings
- auto-rename-tag.activationOnLanguage: ['html', 'xml', 'javascriptreact']

## Requirements
VS Code: 1.50+. No additional dependencies.`,
    features: [
      'Automatically rename paired HTML and XML tags',
      'Support for JSX and TSX files',
      'Customizable language activation list',
      'Undo support for tag renames',
      'Works with multi-cursor editing',
    ],
    changelog: [
      { version: '0.1.10', date: '2023-10-05', notes: 'Fixed tag rename in nested templates. Improved JSX support.' },
      { version: '0.1.9', date: '2023-06-12', notes: 'Added support for self-closing tags. Better handling of attributes.' },
      { version: '0.1.8', date: '2023-02-20', notes: 'Performance improvements for large files. Fixed edge case with void elements.' },
    ],
  },

  {
    id: 'bracket-pair',
    name: 'Bracket Pair Colorizer',
    publisher: 'Coenraads',
    description: 'A customizable extension for colorizing matching brackets',
    version: '1.0.62',
    rating: 4.5,
    downloads: '10.1M',
    iconColor: '#ffd700',
    readme: `# Bracket Pair Colorizer

## Quick Start
Open any code: file. Matching brackets are automatically colorized for easy visual identification.

## Settings
- bracketPairColorizer.depreciation-notice: false
- bracketPairColorizer.colors: ['Gold', 'Orchid', 'LightSkyBlue']

## Requirements
VS Code: 1.60+. Note: This feature is now built into VS Code: natively.`,
    features: [
      'Colorize matching bracket pairs with distinct colors',
      'Customizable color palette for bracket pairs',
      'Support for nested bracket visualization',
      'Active bracket pair highlighting',
      'Works with all programming languages',
    ],
    changelog: [
      { version: '1.0.62', date: '2023-09-01', notes: 'Deprecation notice added. Users should migrate to native bracket pair colorization.' },
      { version: '1.0.61', date: '2022-12-10', notes: 'Fixed color rendering in high-contrast themes. Improved memory usage.' },
      { version: '1.0.60', date: '2022-08-15', notes: 'Performance improvements for deeply nested brackets.' },
    ],
  },

  {
    id: 'path-intellisense',
    name: 'Path Intellisense',
    publisher: 'Christian Kohler',
    description: 'Autocomplete filenames',
    version: '2.8.5',
    rating: 4.3,
    downloads: '14.7M',
    iconColor: '#4CAF50',
    readme: `# Path Intellisense

## Quick Start
Type ./ or ../ in an import or file reference. Autocomplete suggestions for files and folders appear instantly.

## Settings
- path-intellisense.extensionOnImport: true
- path-intellisense.autoSlashAfterDirectory: true

## Requirements
VS Code: 1.55+. No additional dependencies.`,
    features: [
      'Autocomplete file paths in imports and references',
      'Works with JavaScript, TypeScript, CSS, and HTML',
      'Configurable file extension handling',
      'Hidden file filtering options',
      'Support for path aliases and custom mappings',
    ],
    changelog: [
      { version: '2.8.5', date: '2023-11-10', notes: 'Fixed path resolution for monorepos. Improved Windows path handling.' },
      { version: '2.8.0', date: '2023-05-20', notes: 'Added support for tsconfig path aliases. Better directory traversal.' },
      { version: '2.7.0', date: '2023-01-15', notes: 'Performance improvements for large directory trees.' },
    ],
  },

  {
    id: 'one-dark',
    name: 'One Dark Pro',
    publisher: 'BinaryFy',
    description: "Atom's One Dark theme for VS Code:",
    version: '3.17.2',
    rating: 4.6,
    downloads: '9.8M',
    iconColor: '#528bff',
    readme: `# One Dark Pro

## Quick Start
Open Command Palette (Ctrl+Shift+P), type "Color Theme", and select "One Dark Pro".

## Settings
- oneDarkPro.bold: false
- oneDarkPro.vivid: true

## Requirements
VS Code: 1.50+. No additional dependencies.`,
    features: [
      'Faithful recreation of Atom One Dark theme',
      'Bold and vivid color variants available',
      'Italic and no-italic options',
      'Customizable accent colors',
      'Works with all file types and extensions',
    ],
    changelog: [
      { version: '3.17.2', date: '2024-01-05', notes: 'Updated terminal colors for better contrast. Fixed markdown syntax highlighting.' },
      { version: '3.17.0', date: '2023-10-20', notes: 'Added vivid color variant. Improved TypeScript type coloring.' },
      { version: '3.16.0', date: '2023-07-10', notes: 'New sidebar styling options. Better support for semantic highlighting.' },
    ],
  },

  {
    id: 'indent-rainbow',
    name: 'indent-rainbow',
    publisher: 'oderwat',
    description: 'Makes indentation easier to read',
    version: '8.3.1',
    rating: 4.4,
    downloads: '18.3M',
    iconColor: '#ff7b72',
    readme: `# indent-rainbow

## Quick Start
Install and open any indented file. Each indentation level gets a subtle color for easy visual tracking.

## Settings
- indent-rainbow.colors: []
- indent-rainbow.errorColor: 'rgba(128,32,32,0.3)'

## Requirements
VS Code: 1.60+. No additional dependencies.`,
    features: [
      'Colorize each indentation level with a different color',
      'Highlight incorrect indentation with error color',
      'Customizable color palette',
      'Light and dark theme compatible',
      'Configurable indent size matching',
    ],
    changelog: [
      { version: '8.3.1', date: '2023-12-20', notes: 'Fixed tab indentation coloring. Improved performance on large files.' },
      { version: '8.3.0', date: '2023-08-10', notes: 'Added new pastel color scheme. Better handling of mixed tabs and spaces.' },
      { version: '8.2.0', date: '2023-03-15', notes: 'Performance improvements. Added configurable opacity levels.' },
    ],
  },

  {
    id: 'turbo-console',
    name: 'Turbo Console Log',
    publisher: 'ChakrounAnas',
    description: 'Automating the process of writing meaningful log messages',
    version: '2.10.1',
    rating: 4.1,
    downloads: '1.8M',
    iconColor: '#f4d03f',
    readme: `# Turbo Console Log

## Quick Start
Select a variable, press Ctrl+Alt+L (or Cmd+Alt+L) to insert a console.log with the variable name and file location.

## Settings
- turboConsoleLog.wrapLogMessage: false
- turboConsole.logMessagePrefix: '🚀'

## Requirements
VS Code: 1.55+. No additional dependencies.`,
    features: [
      'Insert descriptive console.log with one keystroke',
      'Automatically includes variable name and line number',
      'Delete all console.log statements in a file',
      'Comment/uncomment all log statements',
      'Customizable log message prefix and format',
    ],
    changelog: [
      { version: '2.10.1', date: '2024-01-08', notes: 'Fixed log insertion in template literals. Improved multi-cursor support.' },
      { version: '2.10.0', date: '2023-10-15', notes: 'Added support for console.table and console.dir. Better TypeScript parsing.' },
      { version: '2.9.0', date: '2023-06-20', notes: 'New delete-all-logs command. Improved log comment toggling.' },
    ],
  },

  {
    id: 'git-history',
    name: 'Git History',
    publisher: 'Don Jayamanne',
    description: 'View git log, file history, compare branches',
    version: '0.6.20',
    rating: 4.3,
    downloads: '12.4M',
    iconColor: '#f14c4c',
    readme: `# Git History

## Quick Start
Right-click any file and select "Git: View File History" to see the complete commit history for that file.

## Settings
- gitHistory.showCommitGraph: true
- gitHistory.displayDate: 'relative'

## Requirements
VS Code: 1.60+. Git must be installed.`,
    features: [
      'View detailed git log with graph visualization',
      'Per-file commit history with diff preview',
      'Compare branches and view merge status',
      'View commit details with changed files',
      'Filter history by author, date, or keyword',
    ],
    changelog: [
      { version: '0.6.20', date: '2023-11-25', notes: 'Fixed branch comparison for remote branches. Improved graph rendering.' },
      { version: '0.6.19', date: '2023-07-30', notes: 'Added support for git stash viewing. Better merge conflict visualization.' },
      { version: '0.6.18', date: '2023-04-10', notes: 'Performance improvements for large repositories. Fixed date formatting.' },
    ],
  },

  {
    id: 'better-comments',
    name: 'Better Comments',
    publisher: 'Aaron Bond',
    description: 'Improve your code commenting',
    version: '3.0.2',
    rating: 4.5,
    downloads: '24.6M',
    iconColor: '#4CAF50',
    readme: `# Better Comments

## Quick Start
Add special characters to your comments like !, ?, TODO, or * to colorize them in the editor.

## Settings
- better-comments.tags: [{ tag: '!', color: '#FF2D00' }]

## Requirements
VS Code: 1.55+. No additional dependencies.`,
    features: [
      'Colorize comments based on special tag characters',
      'Built-in tags: ! (alert), ? (question), TODO, * (highlight)',
      'Customizable tag definitions and colors',
      'Works with all programming languages',
      'Multi-line comment support',
    ],
    changelog: [
      { version: '3.0.2', date: '2023-12-12', notes: 'Fixed comment detection in HTML and Vue files. Improved performance.' },
      { version: '3.0.0', date: '2023-08-01', notes: 'Added support for line comment styles per language. New default tags.' },
      { version: '2.1.0', date: '2023-02-15', notes: 'Improved comment parsing for complex cases. Better multi-line handling.' },
    ],
  },

  {
    id: 'todo-tree',
    name: 'Todo Tree',
    publisher: 'Gruntfuggly',
    description: 'Show TODO, FIXME, etc. comment tags',
    version: '0.0.226',
    rating: 4.6,
    downloads: '6.2M',
    iconColor: '#ff9800',
    readme: `# Todo Tree

## Quick Start
Open the Todo Tree panel from the Activity Bar. All TODO, FIXME, and BUG comments from your workspace are listed automatically.

## Settings
- todo-tree.general.tags: ['TODO', 'FIXME', 'BUG', 'HACK']
- todo-tree.tree.showScanModeButton: true

## Requirements
VS Code: 1.65+. No additional dependencies.`,
    features: [
      'Scan workspace for TODO, FIXME, BUG, and HACK comments',
      'Tree view organized by file or by tag type',
      'Customizable tag definitions and regex patterns',
      'Click any item to navigate directly to the comment',
      'Filter and search tags across the workspace',
    ],
    changelog: [
      { version: '0.0.226', date: '2024-01-03', notes: 'Fixed workspace scanning for large repos. Improved tag highlighting.' },
      { version: '0.0.225', date: '2023-09-18', notes: 'Added export to file feature. Better multi-root workspace support.' },
      { version: '0.0.224', date: '2023-05-22', notes: 'Performance improvements for real-time scanning. New icon set.' },
    ],
  },

  {
    id: 'peacock',
    name: 'Peacock',
    publisher: 'John Papa',
    description: 'Subtly change the workspace color',
    version: '4.2.2',
    rating: 4.5,
    downloads: '3.1M',
    iconColor: '#9c27b0',
    readme: `# Peacock

## Quick Start
Open Command Palette (Ctrl+Shift+P) and type "Peacock" to see color options. Choose a color to theme your workspace.

## Settings
- peacock.affectActivityBar: true
- peacock.affectTitleBar: true
- peacock.affectStatusBar: true

## Requirements
VS Code: 1.60+. No additional dependencies.`,
    features: [
      'Customize workspace colors to visually distinguish projects',
      'Apply colors to title bar, activity bar, and status bar',
      'Predefined color palette with favorites support',
      'Save favorite colors for quick application',
      'Surprise Me option for random color selection',
    ],
    changelog: [
      { version: '4.2.2', date: '2023-11-05', notes: 'Fixed color persistence across window reloads. Improved dark mode handling.' },
      { version: '4.2.0', date: '2023-06-15', notes: 'Added new color presets. Better integration with remote workspaces.' },
      { version: '4.1.0', date: '2023-02-28', notes: 'New peacock commands for toggling effects. Improved settings sync.' },
    ],
  },

  {
    id: 'settings-sync',
    name: 'Settings Sync',
    publisher: 'Shan',
    description: 'Synchronize settings, snippets, themes',
    version: '3.4.3',
    rating: 4.0,
    downloads: '2.7M',
    iconColor: '#2196F3',
    readme: `# Settings Sync

## Quick Start
Login with GitHub or Microsoft account to upload your settings. On a new machine, login to download all settings.

## Settings
- sync.gist: ''
- sync.autoDownload: false

## Requirements
VS Code: 1.55+. GitHub or Microsoft account.`,
    features: [
      'Sync settings, keybindings, and snippets across devices',
      'Sync extensions list with auto-install',
      'Upload/download via GitHub Gist',
      'Automated sync on settings change',
      'Selective sync options for specific categories',
    ],
    changelog: [
      { version: '3.4.3', date: '2023-10-10', notes: 'Fixed Gist upload issues. Improved conflict resolution.' },
      { version: '3.4.0', date: '2023-05-05', notes: 'Added Microsoft account support. Better merge handling.' },
      { version: '3.3.0', date: '2023-01-20', notes: 'Performance improvements for large settings files.' },
    ],
  },

  {
    id: 'markdown-all',
    name: 'Markdown All in One',
    publisher: 'Yu Zhang',
    description: 'All you need for Markdown',
    version: '3.6.2',
    rating: 4.6,
    downloads: '16.8M',
    iconColor: '#083fa1',
    readme: `# Markdown All in One

## Quick Start
Open any .md file. Preview with Ctrl+Shift+V. Use Ctrl+B for bold and Ctrl+I for italic.

## Settings
- markdown.extension.preview.autoShowPreviewToSide: false
- markdown.extension.toc.levels: '1-6'

## Requirements
VS Code: 1.60+. No additional dependencies.`,
    features: [
      'Keyboard shortcuts for bold, italic, and strikethrough',
      'Auto-updating table of contents',
      'Live preview with scroll sync',
      'Auto-completion for links and references',
      'Convert to HTML and export options',
    ],
    changelog: [
      { version: '3.6.2', date: '2024-01-12', notes: 'Fixed TOC generation for deep nesting. Improved KaTeX rendering.' },
      { version: '3.6.0', date: '2023-09-25', notes: 'Added Mermaid diagram support in preview. Better GFM compatibility.' },
      { version: '3.5.0', date: '2023-05-15', notes: 'Improved Math rendering. New list continuation feature.' },
    ],
  },

  {
    id: 'yaml',
    name: 'YAML',
    publisher: 'Red Hat',
    description: 'YAML Language Support',
    version: '1.14.0',
    rating: 4.2,
    downloads: '20.1M',
    iconColor: '#cb171e',
    readme: `# YAML

## Quick Start
Open any .yaml or .yml file. Get syntax highlighting, validation, and auto-completion for Kubernetes and other schemas.

## Settings
- yaml.validate: true
- yaml.format.enable: true

## Requirements
VS Code: 1.63+. No additional dependencies.`,
    features: [
      'Syntax highlighting and validation for YAML files',
      'Auto-completion based on JSON schemas',
      'Kubernetes schema support out of the box',
      'Format document and format on save',
      'Hover documentation from schema definitions',
    ],
    changelog: [
      { version: '1.14.0', date: '2023-12-08', notes: 'Updated Kubernetes schemas. Improved validation for anchors and aliases.' },
      { version: '1.13.0', date: '2023-08-22', notes: 'Added Helm chart support. Better error reporting for syntax issues.' },
      { version: '1.12.0', date: '2023-04-15', notes: 'Performance improvements for large YAML files. New schema mapping options.' },
    ],
  },

  {
    id: 'dotenv',
    name: 'DotENV',
    publisher: 'mikestead',
    description: 'Support for dotenv file syntax',
    version: '1.0.1',
    rating: 4.1,
    downloads: '7.5M',
    iconColor: '#f4d03f',
    readme: `# DotENV

## Quick Start
Open any .env file. Syntax highlighting activates automatically for environment variable definitions.

## Settings
No required settings. Works out of the box.

## Requirements
VS Code: 1.40+. No additional dependencies.`,
    features: [
      'Syntax highlighting for .env files',
      'Support for comments and quoted values',
      'Works with all .env variations (.env.local, .env.production)',
      'Highlighting for export statements',
      'Multi-line value support',
    ],
    changelog: [
      { version: '1.0.1', date: '2023-09-10', notes: 'Fixed syntax highlighting for values with equals signs. Improved comment detection.' },
      { version: '1.0.0', date: '2022-12-01', notes: 'Stable release with full .env syntax support.' },
    ],
  },

  {
    id: 'npm-intellisense',
    name: 'npm Intellisense',
    publisher: 'Christian Kohler',
    description: 'Visual Studio Code: plugin that autocompletes npm modules',
    version: '1.4.5',
    rating: 4.2,
    downloads: '5.3M',
    iconColor: '#cb171e',
    readme: `# npm Intellisense

## Quick Start
Start typing an import statement. Installed npm packages are suggested automatically in the autocomplete dropdown.

## Settings
- npm-intellisense.scanDevDependencies: true
- npm-intellisense.showBuildIn: false

## Requirements
VS Code: 1.55+. Node.js project with package.json.`,
    features: [
      'Autocomplete npm packages in import statements',
      'Scans dependencies and devDependencies from package.json',
      'Supports ES6 and CommonJS import styles',
      'Filters scoped packages correctly',
      'Works with subpath imports',
    ],
    changelog: [
      { version: '1.4.5', date: '2023-10-20', notes: 'Fixed scoped package autocomplete. Improved package.json scanning.' },
      { version: '1.4.4', date: '2023-04-05', notes: 'Added support for subpath exports. Better monorepo handling.' },
      { version: '1.4.3', date: '2022-11-15', notes: 'Performance improvements for large node_modules.' },
    ],
  },

  {
    id: 'import-cost',
    name: 'Import Cost',
    publisher: 'Wix',
    description: 'Display import/require package size',
    version: '3.3.0',
    rating: 4.0,
    downloads: '2.9M',
    iconColor: '#ff7b72',
    readme: `# Import Cost

## Quick Start
Open a file with import statements. The size of each imported package is displayed inline next to the import.

## Settings
- importcost.bundleSizeDecoration: 'both'
- importcost.showCalculatingDecoration: true

## Requirements
VS Code: 1.60+. No additional dependencies. Uses webpack for size calculation.`,
    features: [
      'Display inline package size next to import statements',
      'Shows gzipped and minified bundle sizes',
      'Real-time size updates when adding imports',
      'Color-coded size indicators (green, yellow, red)',
      'Supports JavaScript and TypeScript imports',
    ],
    changelog: [
      { version: '3.3.0', date: '2023-11-30', notes: 'Improved webpack 5 compatibility. Better tree-shaking detection.' },
      { version: '3.2.0', date: '2023-06-10', notes: 'Added support for dynamic imports. Fixed size calculation for CSS imports.' },
      { version: '3.1.0', date: '2023-01-25', notes: 'Performance improvements. Better caching for repeated calculations.' },
    ],
  },

  {
    id: 'volar',
    name: 'Volar',
    publisher: 'Vue',
    description: 'VS Code: plugin for Vue language features',
    version: '2.0.7',
    rating: 4.6,
    downloads: '1.5M',
    iconColor: '#41b883',
    readme: `# Volar

## Quick Start
Open a Vue project. Volar provides TypeScript support, template validation, and component auto-import for Vue 3.

## Settings
- volar.takeOverMode.enabled: true
- volar.completion.preferredTagNameCase: 'auto-kebab'

## Requirements
VS Code: 1.80+. Vue 2 or Vue 3 project. TypeScript for enhanced features.`,
    features: [
      'Full TypeScript support for Vue Single File Components',
      'Template type checking and error reporting',
      'Auto-import for Vue components',
      'Refactoring tools for Vue-specific syntax',
      'Take Over Mode replacing the built-in TS extension',
    ],
    changelog: [
      { version: '2.0.7', date: '2024-01-15', notes: 'Improved Vue 3.4 support. Better generic component type inference.' },
      { version: '2.0.0', date: '2023-11-01', notes: 'Major rewrite with improved performance. New hybrid mode for better DX.' },
      { version: '1.8.0', date: '2023-08-20', notes: 'Added defineSlots support. Improved macro resolution.' },
    ],
  },
];
