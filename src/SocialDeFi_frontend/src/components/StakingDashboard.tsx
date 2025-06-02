// components/StakingDashboard.tsx
import { useState } from 'react'
import { useAuth } from '../context/AuthContext'
import { useCanisters } from '../context/CanisterContext'

const StakingDashboard = () => {
    const { identity } = useAuth()
    const { tokenCanister, stakingPool } = useCanisters()
    const [stakeAmount, setStakeAmount] = useState('')

    const handleStake = async () => {
        if (!stakingPool || !identity || !stakeAmount) return

        try {
            const amount = BigInt(Math.floor(Number(stakeAmount) * 1e8))
            await stakingPool.stake(amount)
            setStakeAmount('')
        } catch (error) {
            console.error('Staking failed:', error)
        }
    }

    return (
        <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-xl font-bold mb-4">Staking</h2>
            <input
                type="number"
                className="w-full p-2 border rounded mb-2"
                placeholder="Amount to stake"
                value={stakeAmount}
                onChange={(e) => setStakeAmount(e.target.value)}
            />
            <button
                onClick={handleStake}
                className="w-full bg-green-500 text-white p-2 rounded mb-2"
            >
                Stake
            </button>
            <button
                onClick={async () => {
                    if (!stakingPool || !identity) return
                    await stakingPool.claim()
                }}
                className="w-full bg-purple-500 text-white p-2 rounded"
            >
                Claim Rewards
            </button>
        </div>
    )
}

export default StakingDashboard
