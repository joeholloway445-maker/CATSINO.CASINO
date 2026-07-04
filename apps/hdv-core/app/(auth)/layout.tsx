export default function AuthLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-[#0f0f1a] flex flex-col items-center justify-center px-4">
      <div className="text-purple-500 text-3xl font-mono mb-8 tracking-widest">✦ HDV ✦</div>
      {children}
    </div>
  )
}
