"use client";

import React, { createContext, useContext, useEffect, useState } from "react";
import { BrowserProvider, JsonRpcSigner } from "ethers";

interface EthereumContextType {
    provider: BrowserProvider | null;
    signer: JsonRpcSigner | null;
    account: string | null;
    connect: () => Promise<void>;
    disconnect: () => void;
}

const EthereumContext = createContext<EthereumContextType>({
    provider: null,
    signer: null,
    account: null,
    connect: async () => {},
    disconnect: () => {},
});

export function EthereumProvider({ children }: { children: React.ReactNode }) {
    const [provider, setProvider] = useState<BrowserProvider | null>(null);
    const [signer, setSigner] = useState<JsonRpcSigner | null>(null);
    const [account, setAccount] = useState<string | null>(null);
    const [mounted, setMounted] = useState(false);

    useEffect(() => {
        setMounted(true);
    }, []);

    const connect = async () => {
        if (typeof window !== "undefined" && window.ethereum) {
            try {
                const browserProvider = new BrowserProvider(window.ethereum);
                const accounts = await browserProvider.send("eth_requestAccounts", []);
                if (accounts.length > 0) {
                    const signerInstance = await browserProvider.getSigner();
                    setProvider(browserProvider);
                    setSigner(signerInstance);
                    setAccount(accounts[0]);
                }
            } catch (err) {
                console.error("Failed to connect MetaMask", err);
            }
        } else {
            alert("Please install MetaMask!");
        }
    };

    const disconnect = () => {
        setProvider(null);
        setSigner(null);
        setAccount(null);
    };

    useEffect(() => {
        if (typeof window !== "undefined" && window.ethereum) {
            const handleAccountsChanged = (accounts: string[]) => {
                if (accounts.length > 0) {
                    setAccount(accounts[0]);
                    connect(); // Re-establish provider and signer
                } else {
                    disconnect();
                }
            };
            
            const handleChainChanged = () => window.location.reload();

            window.ethereum.on("accountsChanged", handleAccountsChanged);
            window.ethereum.on("chainChanged", handleChainChanged);

            // check if already connected
            const browserProvider = new BrowserProvider(window.ethereum);
            browserProvider.send("eth_accounts", []).then((accounts) => {
                if (accounts.length > 0) {
                    connect();
                }
            }).catch(console.error);

            return () => {
                if (window.ethereum.removeListener) {
                    window.ethereum.removeListener("accountsChanged", handleAccountsChanged);
                    window.ethereum.removeListener("chainChanged", handleChainChanged);
                }
            };
        }
    }, []);

    return (
        <EthereumContext.Provider value={{ provider, signer, account, connect, disconnect }}>
            {mounted ? children : null}
        </EthereumContext.Provider>
    );
}

export const useEthereum = () => useContext(EthereumContext);
