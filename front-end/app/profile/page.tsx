'use client'

import { useState, useEffect, FormEvent } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { userApi, depositApi } from '@/app/lib/api'
import { getUserIdFromToken } from '@/app/lib/jwt'

export default function ProfilePage() {
  const router = useRouter()
  const [userId, setUserId] = useState<string | null>(null)
  const [userBalance, setUserBalance] = useState<number | null>(null)
  const [depositAmount, setDepositAmount] = useState('')
  const [loading, setLoading] = useState(false)
  const [depositLoading, setDepositLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [loadingBalance, setLoadingBalance] = useState(true)

  useEffect(() => {
    // Check if user is logged in
    const token = localStorage.getItem('accessToken')
    if (!token) {
      router.push('/login')
      return
    }

    // Get user ID from token
    const id = getUserIdFromToken()
    if (!id) {
      setError('Unable to get user information. Please login again.')
      return
    }

    setUserId(id)
    fetchUserBalance(id, token)
  }, [router])

  const fetchUserBalance = async (id: string, token: string) => {
    try {
      setLoadingBalance(true)
      const response = await userApi.getUserById(id, token)
      if (response.success && response.data) {
        setUserBalance(response.data.balance)
      } else {
        setError('Failed to fetch balance')
      }
    } catch (err: any) {
      setError(err.response?.data?.error || 'Failed to fetch balance')
    } finally {
      setLoadingBalance(false)
    }
  }

  const handleDeposit = async (e: FormEvent) => {
    e.preventDefault()
    setError('')
    setSuccess('')
    
    if (!userId) {
      setError('User ID not found. Please login again.')
      return
    }

    const amount = parseFloat(depositAmount)
    if (isNaN(amount) || amount <= 0) {
      setError('Please enter a valid deposit amount')
      return
    }

    // Minimum deposit is $0.50 (50 cents)
    if (amount < 0.5) {
      setError('Minimum deposit amount is $0.50')
      return
    }

    setDepositLoading(true)
    const token = localStorage.getItem('accessToken')

    try {
      // Convert dollars to cents
      const amountInCents = Math.round(amount * 100)
      
      const response = await depositApi.createDeposit(
        {
          userId,
          amount: amountInCents,
          currency: 'usd',
        },
        token || ''
      )

      if (response.success && response.data) {
        setSuccess(`Deposit successful! Your new balance is $${response.data.updatedBalance?.toFixed(2) || userBalance}`)
        setDepositAmount('')
        
        // Refresh balance
        if (token) {
          await fetchUserBalance(userId, token)
        }
      } else {
        setError(response.error || 'Deposit failed. Please try again.')
      }
    } catch (err: any) {
      setError(err.response?.data?.error || 'An error occurred during deposit')
    } finally {
      setDepositLoading(false)
    }
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
        <div className="absolute top-0 left-0 w-96 h-96 bg-casino-gold rounded-full blur-3xl"></div>
        <div className="absolute bottom-0 right-0 w-96 h-96 bg-casino-red rounded-full blur-3xl"></div>
      </div>

      {/* Main Content */}
      <div className="relative z-10 w-full max-w-2xl px-6">
        <div className="bg-gray-900/90 backdrop-blur-lg border border-casino-gold/30 rounded-2xl shadow-2xl p-8">
          {/* Header */}
          <div className="flex justify-between items-center mb-8">
            <div>
              <h1 className="text-4xl font-bold text-casino-gold mb-2">PROFILE</h1>
              <div className="w-20 h-1 bg-gradient-to-r from-transparent via-casino-gold to-transparent"></div>
            </div>
            <div className="flex gap-4">
              <Link
                href="/roulette"
                className="px-4 py-2 bg-casino-gold/20 border border-casino-gold text-casino-gold font-medium rounded-lg hover:bg-casino-gold/30 transition-colors"
              >
                Roulette
              </Link>
              <button
                onClick={handleLogout}
                className="px-4 py-2 bg-casino-red text-white font-medium rounded-lg hover:bg-red-700 transition-colors"
              >
                Logout
              </button>
            </div>
          </div>

          {/* Balance Display */}
          <div className="mb-8 p-6 bg-gradient-to-r from-casino-gold/10 to-yellow-500/10 border border-casino-gold/30 rounded-lg">
            <div className="text-center">
              <p className="text-gray-400 mb-2 text-sm uppercase tracking-wider">Current Balance</p>
              {loadingBalance ? (
                <div className="text-4xl font-bold text-casino-gold animate-pulse">Loading...</div>
              ) : (
                <p className="text-5xl font-bold text-casino-gold">
                  ${userBalance !== null ? userBalance.toFixed(2) : '0.00'}
                </p>
              )}
            </div>
          </div>

          {/* Deposit Section */}
          <div className="mb-8">
            <h2 className="text-2xl font-bold text-casino-gold mb-6">Deposit Money</h2>
            
            {/* Error message */}
            {error && (
              <div className="mb-4 p-4 bg-casino-red/20 border border-casino-red rounded-lg text-red-300 text-sm">
                {error}
              </div>
            )}

            {/* Success message */}
            {success && (
              <div className="mb-4 p-4 bg-green-500/20 border border-green-500 rounded-lg text-green-300 text-sm">
                {success}
              </div>
            )}

            {/* Deposit Form */}
            <form onSubmit={handleDeposit} className="space-y-6">
              <div>
                <label htmlFor="depositAmount" className="block text-gray-300 mb-2 font-medium">
                  Deposit Amount (USD)
                </label>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400 text-xl">$</span>
                  <input
                    id="depositAmount"
                    type="number"
                    step="0.01"
                    min="0.5"
                    value={depositAmount}
                    onChange={(e) => setDepositAmount(e.target.value)}
                    required
                    className="w-full pl-8 pr-4 py-3 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:border-casino-gold focus:ring-2 focus:ring-casino-gold/50 text-white text-lg transition-all"
                    placeholder="0.00"
                  />
                </div>
                <p className="mt-2 text-gray-500 text-sm">Minimum deposit: $0.50</p>
              </div>

              <button
                type="submit"
                disabled={depositLoading || !depositAmount || parseFloat(depositAmount) < 0.5}
                className="w-full py-3 bg-gradient-to-r from-casino-gold to-yellow-500 text-casino-dark font-bold rounded-lg shadow-lg transform transition-all duration-300 hover:scale-105 hover:shadow-casino-gold/50 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
              >
                {depositLoading ? 'PROCESSING DEPOSIT...' : 'DEPOSIT'}
              </button>
            </form>
          </div>

          {/* User Info */}
          <div className="pt-6 border-t border-gray-700">
            <div className="space-y-2 text-sm text-gray-400">
              <p><span className="text-gray-300">User ID:</span> {userId || 'Loading...'}</p>
              <p className="text-xs text-gray-500 mt-4">
                Deposits are processed using Stripe (test mode). Your balance will be updated immediately upon successful deposit.
              </p>
            </div>
          </div>

          {/* Back to home */}
          <div className="mt-6 text-center">
            <Link href="/" className="text-gray-500 hover:text-gray-300 text-sm transition-colors">
              ← Back to home
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}
