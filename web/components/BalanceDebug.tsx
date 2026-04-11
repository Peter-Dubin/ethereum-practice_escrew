"use client";
import React, { useState, useEffect } from 'react';
import { Contract, formatUnits } from 'ethers';
import { useEthereum } from '../lib/ethereum';
import { ESCROW_ADDRESS, TOKEN_A_ADDRESS, TOKEN_B_ADDRESS } from '../lib/contracts';
import ERC20ABI from '../lib/MockERC20.json';

const ACCOUNTS = [
    { name: "ESCROW CONTRACT", addr: ESCROW_ADDRESS },
    { name: "Owner / Acc 0",   addr: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" },
    { name: "User 1 / Acc 1",  addr: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8" },
    { name: "User 2 / Acc 2",  addr: "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC" },
];

export default function BalanceDebug() {
    const { provider } = useEthereum();
    const [balances, setBalances] = useState<Record<string, { eth: string, tka: string, tkb: string }>>({});

    const fetchBalances = async () => {
        if (!provider) return;
        try {
            const tokenA = new Contract(TOKEN_A_ADDRESS, ERC20ABI.abi, provider);
            const tokenB = new Contract(TOKEN_B_ADDRESS, ERC20ABI.abi, provider);
            const newBalances: any = {};
            
            for (const acc of ACCOUNTS) {
                if (!acc.addr) continue;
                const eth = await provider.getBalance(acc.addr);
                const tka = await tokenA.balanceOf(acc.addr);
                const tkb = await tokenB.balanceOf(acc.addr);
                
                newBalances[acc.addr] = {
                    eth: formatUnits(eth, 18),
                    tka: formatUnits(tka, 18),
                    tkb: formatUnits(tkb, 18)
                };
            }
            setBalances(newBalances);
        } catch (e) {
            console.error(e);
        }
    };

    useEffect(() => {
        fetchBalances();
        const interval = setInterval(fetchBalances, 5000);
        return () => clearInterval(interval);
    }, [provider]);

    return (
        <div className="bg-white/[0.03] border border-white/10 rounded-2xl p-6 backdrop-blur-xl shadow-2xl">
            <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-orange-400 to-rose-400">Ledger Debug</h2>
                <button onClick={fetchBalances} className="p-2 rounded-lg bg-white/5 hover:bg-white/10 text-white/50 transition-colors">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" /></svg>
                </button>
            </div>
            
            <div className="flex flex-col gap-3">
                {ACCOUNTS.map((acc, idx) => {
                    if (!acc.addr) return null;
                    const b = balances[acc.addr] || { eth: "0", tka: "0", tkb: "0" };
                    const isEscrow = idx === 0;
                    return (
                        <div key={idx} className={`p-4 rounded-xl border ${isEscrow ? 'bg-orange-500/10 border-orange-500/30' : 'bg-black/30 border-white/5'}`}>
                            <div className="flex justify-between items-end mb-3">
                                <div>
                                    <div className={`text-xs font-bold ${isEscrow ? 'text-orange-400' : 'text-white/60'} tracking-wider uppercase`}>{acc.name}</div>
                                    <div className="text-[10px] font-mono text-white/30 mt-0.5">{acc.addr.slice(0,8)}...{acc.addr.slice(-6)}</div>
                                </div>
                            </div>
                            
                            <div className="grid grid-cols-3 gap-2">
                                <div className="bg-white/5 rounded-lg p-2 text-center">
                                    <div className="text-[9px] text-yellow-400/70 font-bold uppercase mb-1">ETH</div>
                                    <div className="text-sm font-mono text-white/90">{Number(b.eth).toFixed(2)}</div>
                                </div>
                                <div className="bg-white/5 rounded-lg p-2 text-center">
                                    <div className="text-[9px] text-emerald-400/70 font-bold uppercase mb-1">Token A</div>
                                    <div className="text-sm font-mono text-white/90">{Number(b.tka).toFixed(2)}</div>
                                </div>
                                <div className="bg-white/5 rounded-lg p-2 text-center">
                                    <div className="text-[9px] text-cyan-400/70 font-bold uppercase mb-1">Token B</div>
                                    <div className="text-sm font-mono text-white/90">{Number(b.tkb).toFixed(2)}</div>
                                </div>
                            </div>
                        </div>
                    );
                })}
            </div>
        </div>
    );
}
