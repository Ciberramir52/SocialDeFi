// context/AuthContext.tsx
import { createContext, useContext, useState, useEffect } from 'react'
import { AuthClient } from '@dfinity/auth-client'

type AuthContextType = {
  identity: any
  isAuthenticated: boolean
  login: () => Promise<void>
  logout: () => Promise<void>
}

const AuthContext = createContext<AuthContextType>({} as AuthContextType)

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [authClient, setAuthClient] = useState<AuthClient>()
  const [identity, setIdentity] = useState<any>(null)

  useEffect(() => {
    const initAuth = async () => {
      const client = await AuthClient.create()
      setAuthClient(client)
      if (await client.isAuthenticated()) {
        setIdentity(client.getIdentity())
      }
    }
    initAuth()
  }, [])

  const login = async () => {
    if (!authClient) return
    await authClient.login({
      identityProvider: import.meta.env.VITE_DFX_NETWORK === 'ic'
        ? 'https://identity.ic0.app'
        : `http://localhost:4943`,
      onSuccess: () => setIdentity(authClient.getIdentity())
    })
  }

  const logout = async () => {
    if (!authClient) return
    await authClient.logout()
    setIdentity(null)
  }

  return (
    <AuthContext.Provider value={{ identity, isAuthenticated: !!identity, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)