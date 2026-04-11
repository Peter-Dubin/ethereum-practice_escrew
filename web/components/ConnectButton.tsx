"use client";
import React from 'react';
import { useEthereum } from '../lib/ethereum';

export default function ConnectButton() {
    const { account, connect, disconnect } = useEthereum();

    if (!account) {
        return (
            <button 
                onClick={connect} 
                className="px-6 py-2.5 rounded-xl bg-gradient-to-r from-indigo-500 to-purple-600 hover:from-indigo-400 hover:to-purple-500 text-white font-medium transition-all shadow-lg shadow-purple-500/25 active:scale-95 border border-white/10"
            >
                Connect Wallet
            </button>
        );
    }

    return (
        <div className="flex items-center gap-3 bg-white/5 p-1.5 rounded-2xl border border-white/10 backdrop-blur-md">
            <div className="px-4 py-1.5 rounded-xl bg-indigo-500/10 text-indigo-300 font-mono text-sm border border-indigo-500/20">
                {account.slice(0, 6)}...{account.slice(-4)}
            </div>
            <button 
                onClick={disconnect} 
                className="px-4 py-1.5 rounded-xl bg-red-500/10 hover:bg-red-500/20 text-red-400 transition-colors text-sm font-medium border border-red-500/20"
            >
                Disconnect
            </button>
        </div>
    );
}
