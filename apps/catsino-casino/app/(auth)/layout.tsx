import Link from 'next/link'

export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center px-4">
      <Link
        href="/"
        className="font-display font-900 text-3xl tracking-widest text-neon-purple neon-text mb-8"
      >
        CATSINO<span className="text-neon-cyan">.CASINO</span>
      </Link>
      {children}
    </div>
  )
}
