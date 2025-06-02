// context/CanisterContext.tsx
import { createContext, useContext, useEffect, useState } from 'react'
import { Actor, HttpAgent } from '@dfinity/agent'
import { idlFactory as UserCanister } from '../../../declarations/UserCanister'
import { idlFactory as TokenCanister } from '../../../declarations/TokenCanister'
import { idlFactory as StakingPool } from '../../../declarations/StackingPool'
import { idlFactory as NFTCanister } from '../../../declarations/NFTCanister'
import type { _SERVICE as UserCanisterType } from '../../../declarations/UserCanister/UserCanister.did'
import type { _SERVICE as TokenCanisterType } from '../../../declarations/TokenCanister/TokenCanister.did'
import type { _SERVICE as StakingPoolType } from '../../../declarations/StackingPool/StackingPool.did'
import type { _SERVICE as NFTCanisterType } from '../../../declarations/NFTCanister/NFTCanister.did'

type CanisterContextType = {
    userCanister: UserCanisterType | null
    tokenCanister: TokenCanisterType | null
    stakingPool: StakingPoolType | null
    nftCanister: NFTCanisterType | null
}

const CanisterContext = createContext<CanisterContextType>({} as CanisterContextType)

export const CanisterProvider = ({ children }: { children: React.ReactNode }) => {
    const [userCanister, setUserCanister] = useState<UserCanisterType | null>(null)
    const [tokenCanister, setTokenCanister] = useState<TokenCanisterType | null>(null)
    const [stakingPool, setStakingPool] = useState<StakingPoolType | null>(null)
    const [nftCanister, setNftCanister] = useState<NFTCanisterType | null>(null)
    const [agent, setAgent] = useState<HttpAgent>()

    useEffect(() => {
        const newAgent = new HttpAgent({
            host: import.meta.env.VITE_DFX_NETWORK === 'ic'
                ? 'https://ic0.app'
                : 'http://localhost:4943'
        })
        setAgent(newAgent)
    }, [])

    useEffect(() => {
        if (!agent) return

        const createActor = <T,>(idlFactory: any, canisterId: string) => {
            return Actor.createActor<T>(idlFactory, {
                agent,
                canisterId: import.meta.env[canisterId] as string
            })
        }

        setUserCanister(createActor<UserCanisterType>(UserCanister, 'VITE_USER_CANISTER_ID'))
        setTokenCanister(createActor<TokenCanisterType>(TokenCanister, 'VITE_TOKEN_CANISTER_ID'))
        setStakingPool(createActor<StakingPoolType>(StakingPool, 'VITE_STAKINGPOOL_ID'))
        setNftCanister(createActor<NFTCanisterType>(NFTCanister, 'VITE_NFTCANISTER_ID'))
    }, [agent])

    return (
        <CanisterContext.Provider value={{ userCanister, tokenCanister, stakingPool, nftCanister }}>
            {children}
        </CanisterContext.Provider>
    )
}

export const useCanisters = () => useContext(CanisterContext)