// components/Profile.tsx
import { useAuth } from '../context/AuthContext'
import { useCanisters } from '../context/CanisterContext'
import { useState, useEffect } from 'react'
import { Principal } from '@dfinity/principal'

const Profile = () => {
    const { identity } = useAuth()
    const { tokenCanister, nftCanister } = useCanisters()
    const [balance, setBalance] = useState<string>('0.00')
    const [nfts, setNfts] = useState<any[]>([])

    useEffect(() => {
        if (!identity || !tokenCanister || !nftCanister) return

        const loadData = async () => {
            const principal = identity.getPrincipal()

            const balance = await tokenCanister.icrc1_balance_of({
                account: principal
            })
            setBalance((Number(balance) / 1e8).toFixed(2))

            const nfts = await nftCanister.getNFTsByOwner(principal)
            setNfts(nfts)
        }

        loadData()
    }, [identity, tokenCanister, nftCanister])

    return (
        <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-xl font-bold mb-4">Profile</h2>
            <p className="truncate">Principal: {identity?.getPrincipal().toText()}</p>
            <p className="mt-2">Balance: {balance} SOCIAL</p>

            <div className="mt-4">
                <h3 className="text-lg font-semibold mb-2">NFT Badges</h3>
                <div className="grid grid-cols-2 gap-2">
                    {nfts.map(nft => (
                        <div key={nft.id} className="border p-2 rounded">
                            <p className="text-center">{nft.metadata}</p>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    )
}

export default Profile
