declare module 'ic-use-internet-identity' {
    export const InternetIdentityProvider: React.FC<{ children: React.ReactNode }>;
    export const useInternetIdentity: () => {
        identity: any;
        isAuthenticated: boolean;
        login: () => void;
        logout: () => void;
        loginStatus: 'idle' | 'logging-in' | 'success' | 'error';
    };
}