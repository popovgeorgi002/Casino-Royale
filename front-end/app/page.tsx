'use client'

import Link from 'next/link'
import { useEffect } from 'react'
import { useRouter } from 'next/navigation'

export default function Home() {
  const router = useRouter()

  useEffect(() => {
    // Check if user is already logged in
    const token = localStorage.getItem('accessToken')
    if (token) {
      router.push('/roulette')
    }
  }, [router])

  return (
    <div className="min-h-screen flex flex-col items-center justify-center relative overflow-hidden">
      {/* Animated background */}
      <div className="absolute inset-0 bg-gradient-to-br from-casino-dark via-gray-900 to-casino-dark"></div>
      <div className="absolute inset-0 opacity-20">
        <div className="absolute top-20 left-20 w-72 h-72 bg-casino-gold rounded-full blur-3xl"></div>
        <div className="absolute bottom-20 right-20 w-96 h-96 bg-casino-red rounded-full blur-3xl"></div>
      </div>

      {/* Main content */}
      <div className="relative z-10 text-center px-4">
        {/* Logo/Title */}
        <div className="mb-12">
          <h1 className="text-7xl md:text-9xl font-bold mb-4 bg-gradient-to-r from-casino-gold via-yellow-400 to-casino-gold bg-clip-text text-transparent animate-pulse">
            CASINO
          </h1>
          <h2 className="text-3xl md:text-5xl font-light text-gray-300 tracking-widest">
            ROYALE
          </h2>
          <div className="mt-6 w-32 h-1 bg-gradient-to-r from-transparent via-casino-gold to-transparent mx-auto"></div>
        </div>

        {/* Tagline */}
        <p className="text-xl md:text-2xl text-gray-400 mb-16 font-light">
          Experience the thrill of the game
        </p>

        {/* Action buttons */}
        <div className="flex flex-col sm:flex-row gap-6 justify-center items-center">
          <Link
            href="/login"
            className="group relative px-12 py-4 bg-gradient-to-r from-casino-gold to-yellow-500 text-casino-dark font-bold text-lg rounded-lg shadow-2xl transform transition-all duration-300 hover:scale-110 hover:shadow-casino-gold/50"
          >
            <span className="relative z-10">LOGIN</span>
            <div className="absolute inset-0 bg-gradient-to-r from-yellow-500 to-casino-gold rounded-lg opacity-0 group-hover:opacity-100 transition-opacity"></div>
          </Link>

          <Link
            href="/register"
            className="group relative px-12 py-4 bg-transparent border-2 border-casino-gold text-casino-gold font-bold text-lg rounded-lg shadow-2xl transform transition-all duration-300 hover:scale-110 hover:bg-casino-gold hover:text-casino-dark"
          >
            <span className="relative z-10">REGISTER</span>
          </Link>
        </div>

        {/* Decorative elements */}
        <div className="mt-20 flex justify-center gap-4">
          <div className="w-2 h-2 bg-casino-gold rounded-full animate-pulse"></div>
          <div className="w-2 h-2 bg-casino-gold rounded-full animate-pulse delay-75"></div>
          <div className="w-2 h-2 bg-casino-gold rounded-full animate-pulse delay-150"></div>
        </div>
      </div>

      {/* Footer */}
      <div className="absolute bottom-8 left-0 right-0 text-center text-gray-500 text-sm">
        <p>© 2025 Casino Royale. Play responsibly.</p>
      </div>
    </div>
  )
}
