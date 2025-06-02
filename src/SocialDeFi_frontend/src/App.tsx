// App.tsx
import { useState, useEffect } from 'react'
import { useAuth } from './context/AuthContext'
import { Principal } from '@dfinity/principal'
import { Actor, HttpAgent } from '@dfinity/agent'
import { idlFactory as userIDL } from '../../declarations/UserCanister'
import { idlFactory as tokenIDL } from '../../declarations/TokenCanister'
import { idlFactory as stakingIDL } from '../../declarations/StackingPool'
import { idlFactory as nftIDL } from '../../declarations/NFTCanister'
import type {
  UserProfile,
  Post,
} from '../../declarations/UserCanister/UserCanister.did'

export default function App() {
  const { isAuthenticated, login, logout, identity } = useAuth()
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null)
  const [balance, setBalance] = useState<string>('0.00')
  const [posts, setPosts] = useState<Post[]>([])
  const [nfts, setNFTs] = useState<Array<{ id: string; metadata: string }>>([])
  const [stakeAmount, setStakeAmount] = useState('')

  // Initialize actors
  const [agent, setAgent] = useState<HttpAgent>()
  const [userActor, setUserActor] = useState<any>()
  const [tokenActor, setTokenActor] = useState<any>()
  const [stakingActor, setStakingActor] = useState<any>()
  const [nftActor, setNFTActor] = useState<any>()

  useEffect(() => {
    if (!identity) return

    const newAgent = new HttpAgent({ 
      host: import.meta.env.DFX_NETWORK === 'ic' 
        ? 'https://ic0.app' 
        : 'http://localhost:4943',
      identity
    })
    setAgent(newAgent)
  }, [identity])

  useEffect(() => {
    if (!agent) return

    setUserActor(createActor(userIDL, 'UserCanister'))
    setTokenActor(createActor(tokenIDL, 'TokenCanister'))
    setStakingActor(createActor(stakingIDL, 'StakingPool'))
    setNFTActor(createActor(nftIDL, 'NFTCanister'))
  }, [agent])

  const createActor = (idlFactory: any, canisterName: string) => {
    return Actor.createActor(idlFactory, {
      agent,
      canisterId: import.meta.env[`VITE_${canisterName.toUpperCase()}_CANISTER_ID`] as string
    })
  }

  useEffect(() => {
    if (!isAuthenticated || !userActor || !tokenActor || !nftActor) return

    const loadData = async () => {
      try {
        const profile = await userActor.authenticate()
        setUserProfile(profile)

        const balance = await tokenActor.icrc1_balance_of({ 
          account: Principal.fromText(profile.principalId) 
        })
        setBalance((Number(balance) / 1e8).toFixed(2))

        const posts = await userActor.getAllPosts()
        setPosts(posts)

        const nfts = await nftActor.getNFTsByOwner(Principal.fromText(profile.principalId))
        setNFTs(nfts)
      } catch (error) {
        console.error('Failed to load data:', error)
      }
    }

    loadData()
  }, [isAuthenticated, userActor, tokenActor, nftActor])

  const handleCreatePost = async (content: string) => {
    if (!userActor) return
    try {
      await userActor.createPost(content)
      const updatedPosts = await userActor.getAllPosts()
      setPosts(updatedPosts)
    } catch (error) {
      console.error('Failed to create post:', error)
    }
  }

  const handleStake = async () => {
    if (!stakingActor || !tokenActor || !userProfile) return
    
    try {
      const amount = Number(stakeAmount) * 1e8
      await stakingActor.stake(amount)
      
      const balance = await tokenActor.icrc1_balance_of({ 
        account: Principal.fromText(userProfile.principalId) 
      })
      setBalance((Number(balance) / 1e8).toFixed(2))
      setStakeAmount('')
    } catch (error) {
      console.error('Failed to stake tokens:', error)
    }
  }

  return (
    <div className="min-h-screen bg-gray-100">
      <nav className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 py-3 flex justify-between items-center">
          <h1 className="text-xl font-bold">SocialDeFi</h1>
          {isAuthenticated ? (
            <button 
              onClick={logout}
              className="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
            >
              Logout
            </button>
          ) : (
            <button
              onClick={login}
              className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
            >
              Login with II
            </button>
          )}
        </div>
      </nav>

      <main className="max-w-7xl mx-auto px-4 py-6">
        {isAuthenticated && userProfile && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Profile Section */}
            <div className="bg-white p-6 rounded-lg shadow">
              <h2 className="text-lg font-semibold mb-4">Profile</h2>
              <p className="text-gray-600 truncate">
                Principal: {userProfile.principalId}
              </p>
              <p className="text-gray-600">Balance: {balance} SOCIAL</p>
              
              <div className="mt-4">
                <h3 className="font-medium mb-2">NFT Badges</h3>
                <div className="grid grid-cols-2 gap-2">
                  {nfts.map(nft => (
                    <div key={nft.id} className="border p-2 rounded">
                      <p className="text-sm text-center">{nft.metadata}</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Social Feed */}
            <div className="md:col-span-2 bg-white p-6 rounded-lg shadow">
              <h2 className="text-lg font-semibold mb-4">Social Feed</h2>
              <div className="mb-4">
                <textarea
                  className="w-full p-2 border rounded"
                  placeholder="What's happening?"
                  onKeyDown={(e) => {
                    if (e.key === 'Enter' && !e.shiftKey) {
                      handleCreatePost(e.currentTarget.value)
                      e.currentTarget.value = ''
                    }
                  }}
                />
              </div>
              <div className="space-y-4">
                {posts.map(post => (
                  <div key={post.id} className="border-b pb-4">
                    <p className="font-medium">{post.authorId}</p>
                    <p className="text-gray-600">{post.content}</p>
                    <button 
                      onClick={() => userActor.likePost(post.id)}
                      className="text-blue-500 hover:text-blue-700"
                    >
                      Like ({post.likes.length})
                    </button>
                  </div>
                ))}
              </div>
            </div>

            {/* Staking Dashboard */}
            <div className="bg-white p-6 rounded-lg shadow">
              <h2 className="text-lg font-semibold mb-4">Staking</h2>
              <input
                type="number"
                className="w-full p-2 border rounded mb-4"
                placeholder="Amount to stake"
                value={stakeAmount}
                onChange={(e) => setStakeAmount(e.target.value)}
              />
              <button
                onClick={handleStake}
                className="w-full bg-green-500 text-white p-2 rounded hover:bg-green-600 mb-2"
              >
                Stake
              </button>
              <button
                onClick={async () => {
                  await stakingActor.claim()
                  const balance = await tokenActor.icrc1_balance_of({ 
                    account: Principal.fromText(userProfile.principalId) 
                  })
                  setBalance((Number(balance) / 1e8).toFixed(2))
                }}
                className="w-full bg-purple-500 text-white p-2 rounded hover:bg-purple-600"
              >
                Claim Rewards
              </button>
            </div>
          </div>
        )}
      </main>
    </div>
  )
}