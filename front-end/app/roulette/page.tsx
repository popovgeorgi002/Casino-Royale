'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { userApi } from '@/app/lib/api'
import { getUserIdFromToken } from '@/app/lib/jwt'

export default function RoulettePage() {
  const router = useRouter()
  const [balance, setBalance] = useState('')
  const [userBalance, setUserBalance] = useState<number | null>(null)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    // Check if user is logged in
    const token = localStorage.getItem('accessToken')
    if (!token) {
      router.push('/login')
      return
    }

    // Fetch user balance
    const userId = getUserIdFromToken()
    if (userId) {
      fetchUserBalance(userId, token)
    }
  }, [router])

  const fetchUserBalance = async (userId: string, token: string) => {
    try {
      const response = await userApi.getUserById(userId, token)
      if (response.success && response.data) {
        setUserBalance(response.data.balance)
      }
    } catch (err) {
      console.error('Failed to fetch balance:', err)
    }
  }

  const handleBet = () => {
    // TODO: Implement bet logic
    console.log('Bet amount:', balance)
  }

  const handleLogout = () => {
    localStorage.removeItem('accessToken')
    localStorage.removeItem('refreshToken')
    router.push('/')
  }

  return (
    <div className="min-h-screen flex flex-col items-center justify-center relative overflow-hidden">
      {/* Background */}
      <div className="absolute inset-0 bg-gradient-to-br from-casino-dark via-gray-900 to-casino-dark"></div>
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-casino-gold rounded-full blur-3xl"></div>
        <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-casino-red rounded-full blur-3xl"></div>
      </div>

      {/* Header */}
      <div className="relative z-10 w-full max-w-6xl px-6 mb-8">
        <div className="flex justify-between items-center">
          <h1 className="text-5xl font-bold text-casino-gold">ROULETTE</h1>
          <div className="flex gap-4">
            <Link
              href="/profile"
              className="px-6 py-2 bg-casino-gold/20 border border-casino-gold text-casino-gold font-medium rounded-lg hover:bg-casino-gold/30 transition-colors"
            >
              Profile
            </Link>
            <button
              onClick={handleLogout}
              className="px-6 py-2 bg-casino-red text-white font-medium rounded-lg hover:bg-red-700 transition-colors"
            >
              Logout
            </button>
          </div>
        </div>
      </div>

      {/* Main Game Area */}
      <div className="relative z-10 w-full max-w-6xl px-6">
        <div className="bg-gray-900/90 backdrop-blur-lg border border-casino-gold/30 rounded-2xl shadow-2xl p-8">
          {/* Roulette Wheel Visual Placeholder */}
          <div className="mb-8 flex justify-center">
            <div className="w-96 h-96 rounded-full border-8 border-casino-gold bg-gradient-to-br from-casino-red via-casino-dark to-casino-green relative overflow-hidden">
              {/* Wheel segments */}
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="text-6xl font-bold text-casino-gold">🎰</div>
              </div>
              {/* Spinning indicator */}
              <div className="absolute top-0 left-1/2 transform -translate-x-1/2 w-4 h-8 bg-casino-gold rounded-t-full"></div>
            </div>
          </div>

          {/* Balance Display */}
          {userBalance !== null && (
            <div className="mb-6 text-center">
              <p className="text-gray-400 mb-2">Your Balance</p>
              <p className="text-4xl font-bold text-casino-gold">${userBalance.toLocaleString()}</p>
            </div>
          )}

          {/* Bet Input Section */}
          <div className="max-w-md mx-auto space-y-6">
            <div>
              <label htmlFor="balance" className="block text-gray-300 mb-2 font-medium text-center">
                Enter Bet Amount
              </label>
              <input
                id="balance"
                type="number"
                value={balance}
                onChange={(e) => setBalance(e.target.value)}
                min="1"
                className="w-full px-6 py-4 bg-gray-800 border-2 border-casino-gold rounded-lg focus:outline-none focus:ring-4 focus:ring-casino-gold/50 text-white text-center text-2xl font-bold transition-all"
                placeholder="0"
              />
            </div>

            <button
              onClick={handleBet}
              disabled={!balance || parseFloat(balance) <= 0 || loading}
              className="w-full py-4 bg-gradient-to-r from-casino-gold to-yellow-500 text-casino-dark font-bold text-xl rounded-lg shadow-2xl transform transition-all duration-300 hover:scale-105 hover:shadow-casino-gold/50 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
            >
              {loading ? 'PLACING BET...' : 'BET'}
            </button>
          </div>

          {/* Game Info */}
          <div className="mt-8 text-center text-gray-400 text-sm">
            <p>Place your bet and spin the wheel</p>
          </div>
        </div>
      </div>
    </div>
  )
}
