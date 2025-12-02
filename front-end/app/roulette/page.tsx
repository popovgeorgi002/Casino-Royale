'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { userApi } from '@/app/lib/api'
import { getUserIdFromToken } from '@/app/lib/jwt'

type GameResult = 'win' | 'lose' | null
type GameState = 'idle' | 'spinning' | 'result'

export default function RoulettePage() {
  const router = useRouter()
  const [betAmount, setBetAmount] = useState('')
  const [userBalance, setUserBalance] = useState<number | null>(null)
  const [gameState, setGameState] = useState<GameState>('idle')
  const [gameResult, setGameResult] = useState<GameResult>(null)
  const [winAmount, setWinAmount] = useState<number>(0)
  const [spinning, setSpinning] = useState(false)
  const [error, setError] = useState('')
  const [wheelRotation, setWheelRotation] = useState(0)

  useEffect(() => {
    const token = localStorage.getItem('accessToken')
    if (!token) {
      router.push('/login')
      return
    }

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
        return response.data.balance
      }
    } catch (err) {
      console.error('Failed to fetch balance:', err)
    }
    return null
  }

  const handleBet = async () => {
    setError('')
    setGameResult(null)
    
    const token = localStorage.getItem('accessToken')
    if (!token) {
      router.push('/login')
      return
    }

    const userId = getUserIdFromToken()
    if (!userId) {
      setError('User ID not found. Please login again.')
      return
    }

    const bet = parseFloat(betAmount)
    if (isNaN(bet) || bet <= 0) {
      setError('Please enter a valid bet amount')
      return
    }

    if (userBalance === null || bet > userBalance) {
      setError('Insufficient balance')
      return
    }

    setGameState('spinning')
    setSpinning(true)
    
    const baseRotation = 360 * 5
    const randomAngle = Math.random() * 360
    const totalRotation = baseRotation + randomAngle
    setWheelRotation(prev => prev + totalRotation)

    setTimeout(async () => {
      const isWin = Math.random() >= 0.5
      const result: GameResult = isWin ? 'win' : 'lose'
      setGameResult(result)
      setSpinning(false)
      setGameState('result')

      const currentBalance = userBalance || 0

      let newBalance: number
      if (isWin) {
        const winnings = bet * 2
        newBalance = currentBalance - bet + winnings
        setWinAmount(winnings)
      } else {
        newBalance = currentBalance - bet
        setWinAmount(0)
      }

      console.log(`[ROULETTE] Game result: ${result}`)
      console.log(`[ROULETTE] Bet: $${bet}, Current balance: $${currentBalance}, New balance: $${newBalance}`)
      console.log(`[ROULETTE] Calling updateBalance for user ${userId}`)
      
      try {
        await updateBalance(userId, newBalance, token)
        console.log(`[ROULETTE] Balance update completed successfully`)
      } catch (error) {
        console.error(`[ROULETTE] Balance update failed:`, error)
        setError('Failed to update balance. Please check the console for details.')
      }
    }, 3000)
  }

  const updateBalance = async (userId: string, newBalance: number, token: string) => {
    try {
      console.log(`Updating balance for user ${userId} to ${newBalance}`)
      const response = await userApi.updateBalance(userId, newBalance, token)
      console.log('Balance update response:', response)
      
      if (response.success && response.data) {
        const updatedBalance = response.data.balance
        setUserBalance(updatedBalance)
        console.log(`Balance updated successfully to ${updatedBalance}`)
        
        setTimeout(async () => {
          try {
            const verifiedBalance = await fetchUserBalance(userId, token)
            if (verifiedBalance !== null && Math.abs(verifiedBalance - updatedBalance) > 0.01) {
              console.warn(`Balance mismatch: Expected ${updatedBalance}, Got ${verifiedBalance}`)
              setUserBalance(verifiedBalance)
            }
          } catch (refreshErr) {
            console.error('Failed to verify balance:', refreshErr)
          }
        }, 1000)
      } else {
        const errorMsg = response.error || 'Failed to update balance. Please refresh the page.'
        setError(errorMsg)
        console.error('Balance update failed:', errorMsg)
        
        await fetchUserBalance(userId, token)
      }
    } catch (err: any) {
      console.error('Error updating balance:', err)
      const errorMessage = err.response?.data?.error || err.message || 'Failed to update balance'
      setError(errorMessage)
      
      try {
        await fetchUserBalance(userId, token)
      } catch (refreshErr) {
        console.error('Failed to refresh balance:', refreshErr)
        setError('Failed to update balance. Please check your connection and try again.')
      }
    }
  }

  const handleNewGame = () => {
    setGameState('idle')
    setGameResult(null)
    setBetAmount('')
    setWinAmount(0)
    setError('')
  }

  const handleLogout = () => {
    localStorage.removeItem('accessToken')
    localStorage.removeItem('refreshToken')
    router.push('/')
  }

  const getWheelColor = () => {
    if (spinning) return 'from-casino-gold via-yellow-400 to-casino-gold'
    if (gameResult === 'win') return 'from-green-500 via-casino-green to-green-500'
    if (gameResult === 'lose') return 'from-casino-red via-red-600 to-casino-red'
    return 'from-casino-red via-casino-dark to-casino-green'
  }

  return (
    <div className="min-h-screen flex flex-col items-center justify-center relative overflow-hidden">
      <div className="absolute inset-0 bg-gradient-to-br from-casino-dark via-gray-900 to-casino-dark"></div>
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-casino-gold rounded-full blur-3xl"></div>
        <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-casino-red rounded-full blur-3xl"></div>
      </div>

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

      <div className="relative z-10 w-full max-w-6xl px-6">
        <div className="bg-gray-900/90 backdrop-blur-lg border border-casino-gold/30 rounded-2xl shadow-2xl p-8">
          {userBalance !== null && (
            <div className="mb-6 text-center">
              <p className="text-gray-400 mb-2">Your Balance</p>
              <p className="text-4xl font-bold text-casino-gold">${userBalance.toFixed(2)}</p>
            </div>
          )}

          <div className="mb-8 flex flex-col items-center">
            <div className="relative">
              <div
                className={`w-96 h-96 rounded-full border-8 border-casino-gold bg-gradient-to-br ${getWheelColor()} relative overflow-hidden transition-all duration-300 ${
                  spinning ? 'animate-spin' : ''
                }`}
                style={{
                  transform: `rotate(${wheelRotation}deg)`,
                  transition: spinning ? 'none' : 'transform 0.5s ease-out',
                }}
              >
                <div className="absolute inset-0">
                  {Array.from({ length: 18 }).map((_, i) => (
                    <div
                      key={i}
                      className="absolute"
                      style={{
                        transform: `rotate(${i * 20}deg)`,
                        transformOrigin: '50% 50%',
                      }}
                    >
                      <div
                        className={`w-48 h-2 ${
                          i % 2 === 0 ? 'bg-casino-red' : 'bg-casino-dark'
                        }`}
                        style={{
                          transform: 'translateX(50%)',
                        }}
                      />
                    </div>
                  ))}
                </div>
                
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="w-32 h-32 rounded-full bg-casino-gold border-4 border-casino-dark flex items-center justify-center">
                    <div className="text-4xl font-bold text-casino-dark">
                      {spinning ? '🎰' : gameResult === 'win' ? '🎉' : gameResult === 'lose' ? '❌' : '🎲'}
                    </div>
                  </div>
                </div>
                
                <div className="absolute top-0 left-1/2 transform -translate-x-1/2 w-4 h-8 bg-casino-gold rounded-t-full z-10 shadow-lg"></div>
              </div>
            </div>

            {gameResult && (
              <div className={`mt-6 p-6 rounded-lg border-2 ${
                gameResult === 'win' 
                  ? 'bg-green-500/20 border-green-500' 
                  : 'bg-casino-red/20 border-casino-red'
              }`}>
                <h2 className={`text-3xl font-bold text-center mb-2 ${
                  gameResult === 'win' ? 'text-green-400' : 'text-red-400'
                }`}>
                  {gameResult === 'win' ? '🎉 YOU WIN! 🎉' : '❌ YOU LOSE ❌'}
                </h2>
                {gameResult === 'win' && (
                  <p className="text-xl text-center text-green-300">
                    You won ${winAmount.toFixed(2)}! (2x your bet)
                  </p>
                )}
                {gameResult === 'lose' && (
                  <p className="text-xl text-center text-red-300">
                    You lost ${parseFloat(betAmount).toFixed(2)}
                  </p>
                )}
              </div>
            )}
          </div>

          {error && (
            <div className="mb-6 p-4 bg-casino-red/20 border border-casino-red rounded-lg text-red-300 text-sm text-center">
              {error}
            </div>
          )}

          {gameState === 'idle' && (
            <div className="max-w-md mx-auto space-y-6">
              <div>
                <label htmlFor="betAmount" className="block text-gray-300 mb-2 font-medium text-center">
                  Enter Bet Amount
                </label>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400 text-xl">$</span>
                  <input
                    id="betAmount"
                    type="number"
                    step="0.01"
                    min="0.01"
                    value={betAmount}
                    onChange={(e) => setBetAmount(e.target.value)}
                    className="w-full pl-8 pr-4 py-4 bg-gray-800 border-2 border-casino-gold rounded-lg focus:outline-none focus:ring-4 focus:ring-casino-gold/50 text-white text-center text-2xl font-bold transition-all"
                    placeholder="0.00"
                  />
                </div>
                <p className="mt-2 text-gray-500 text-sm text-center">
                  Win: 2x your bet | Lose: Your bet
                </p>
              </div>

              <button
                onClick={handleBet}
                disabled={!betAmount || parseFloat(betAmount) <= 0 || userBalance === null || parseFloat(betAmount) > (userBalance || 0)}
                className="w-full py-4 bg-gradient-to-r from-casino-gold to-yellow-500 text-casino-dark font-bold text-xl rounded-lg shadow-2xl transform transition-all duration-300 hover:scale-105 hover:shadow-casino-gold/50 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none"
              >
                SPIN THE WHEEL
              </button>
            </div>
          )}

          {gameState === 'spinning' && (
            <div className="text-center">
              <p className="text-2xl font-bold text-casino-gold animate-pulse">SPINNING...</p>
              <p className="text-gray-400 mt-2">Good luck!</p>
            </div>
          )}

          {gameState === 'result' && (
            <div className="text-center">
              <button
                onClick={handleNewGame}
                className="px-8 py-3 bg-gradient-to-r from-casino-gold to-yellow-500 text-casino-dark font-bold text-lg rounded-lg shadow-lg transform transition-all duration-300 hover:scale-105 hover:shadow-casino-gold/50"
              >
                PLAY AGAIN
              </button>
            </div>
          )}

          <div className="mt-8 text-center text-gray-400 text-sm">
            <p>50% chance to win 2x your bet</p>
            <p className="mt-1">Place your bet and spin the wheel!</p>
          </div>
        </div>
      </div>
    </div>
  )
}
