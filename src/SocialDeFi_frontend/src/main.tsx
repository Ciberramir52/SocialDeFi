import React from 'react'
import ReactDOM from 'react-dom/client'
import { InternetIdentityProvider } from 'ic-use-internet-identity'
import { AuthProvider } from './context/AuthContext'
import { CanisterProvider } from './context/CanisterContext'
import App from './App'
import './index.scss'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <InternetIdentityProvider>
      <AuthProvider>
        <CanisterProvider>
          <App />
        </CanisterProvider>
      </AuthProvider>
    </InternetIdentityProvider>
  </React.StrictMode>
)