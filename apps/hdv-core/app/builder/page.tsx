import BuilderShellLoader from '@/components/builder/BuilderShellLoader'

export const metadata = {
  title: 'Builder · HDV Core',
  description: 'VS Code-replica build surface — file explorer, Monaco editor, terminal, and a real Claude REPL wired into PersonaMatrix.',
}

export default function BuilderPage() {
  return <BuilderShellLoader />
}
