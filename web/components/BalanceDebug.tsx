"use client";
import React, { useState, useEffect, useRef } from 'react';
import { Contract, formatUnits } from 'ethers';
import { useEthereum } from '../lib/ethereum';
import { ESCROW_ADDRESS } from '../lib/contracts';
import EscrowABI from '../lib/Escrow.json';
import ERC20ABI from '../lib/MockERC20.json';

const ACCOUNTS = [
    { name: "ESCROW CONTRACT", addr: ESCROW_ADDRESS },
    { name: "Owner / Acc 0",   addr: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" },
    { name: "User 1 / Acc 1",  addr: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8" },
    { name: "User 2 / Acc 2",  addr: "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC" },
];

const TOKEN_COLORS = [
    'text-emerald-400/70',
    'text-cyan-400/70',
    'text-violet-400/70',
    'text-rose-400/70',
    'text-amber-400/70',
    'text-sky-400/70',
    'text-pink-400/70',
];

export default function BalanceDebug() {
    const { provider } = useEthereum();
    const [tokens, setTokens] = useState<Array<{ address: string; symbol: string }>>([]);
    const [balances, setBalances] = useState<Record<string, { eth: string; [tokenAddr: string]: string }>>({});
    const fetchingRef = useRef(false);

    const fetchData = async () => {
        if (!provider || fetchingRef.current) return;
        fetchingRef.current = true;
        try {
            const escrow = new Contract(ESCROW_ADDRESS, EscrowABI.abi, provider);
            let tokenAddrs: string[] = [];
            try {
                tokenAddrs = await escrow.getAllowedTokens();
            } catch {
                // Escrow not yet deployed or unavailable — keep empty list
            }

            const tokenInfos = await Promise.all(
                (tokenAddrs || []).map(async (addr) => {
                    try {
                        const tc = new Contract(addr, ERC20ABI.abi, provider);
                        const symbol: string = await tc.symbol();
                        return { address: addr, symbol };
                    } catch {
                        return { address: addr, symbol: '???' };
                    }
                })
            );
            setTokens(tokenInfos);

            const newBalances: Record<string, { eth: string; [k: string]: string }> = {};
            for (const acc of ACCOUNTS) {
                if (!acc.addr) continue;
                let ethBal = "0";
                try {
                    const raw = await provider.getBalance(acc.addr);
                    ethBal = formatUnits(raw, 18);
                } catch { /* keep 0 */ }

                const entry: { eth: string; [k: string]: string } = { eth: ethBal };
                for (const ti of tokenInfos) {
                    try {
                        const tc = new Contract(ti.address, ERC20ABI.abi, provider);
                        const bal = await tc.balanceOf(acc.addr);
                        entry[ti.address.toLowerCase()] = formatUnits(bal, 18);
                    } catch {
                        entry[ti.address.toLowerCase()] = "—";
                    }
                }
                newBalances[acc.addr] = entry;
            }
            setBalances(newBalances);
        } catch (e) {
            console.error(e);
        } finally {
            fetchingRef.current = false;
        }
    };

    useEffect(() => {
        fetchData();
        const interval = setInterval(fetchData, 5000);
        return () => clearInterval(interval);
    }, [provider]);

    return (
        <div className="bg-white/[0.03] border border-white/10 rounded-2xl p-6 backdrop-blur-xl shadow-2xl">
            <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-orange-400 to-rose-400">Ledger Debug</h2>
                <button onClick={fetchData} className="p-2 rounded-lg bg-white/5 hover:bg-white/10 text-white/50 transition-colors">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" /></svg>
                </button>
            </div>

            <div className="flex flex-col gap-3">
                {ACCOUNTS.map((acc, idx) => {
                    if (!acc.addr) return null;
                    const b = balances[acc.addr] || {};
                    const isEscrow = idx === 0;
                    const colCount = 1 + tokens.length;
                    return (
                        <div key={idx} className={`p-4 rounded-xl border ${isEscrow ? 'bg-orange-500/10 border-orange-500/30' : 'bg-black/30 border-white/5'}`}>
                            <div className="flex justify-between items-end mb-3">
                                <div>
                                    <div className={`text-xs font-bold ${isEscrow ? 'text-orange-400' : 'text-white/60'} tracking-wider uppercase`}>{acc.name}</div>
                                    <div className="text-[10px] font-mono text-white/30 mt-0.5">{acc.addr.slice(0, 8)}...{acc.addr.slice(-6)}</div>
                                </div>
                            </div>

                            <div
                                className="grid gap-2"
                                style={{ gridTemplateColumns: `repeat(${colCount}, minmax(0, 1fr))` }}
                            >
                                <div className="bg-white/5 rounded-lg p-2 text-center">
                                    <div className="text-[9px] text-yellow-400/70 font-bold uppercase mb-1">ETH</div>
                                    <div className="text-sm font-mono text-white/90">{Number(b.eth || 0).toFixed(2)}</div>
                                </div>
                                {tokens.map((ti, tidx) => {
                                    const val = b[ti.address.toLowerCase()];
                                    const display = val === "—" ? "—" : Number(val || 0).toFixed(2);
                                    return (
                                        <div key={ti.address} className="bg-white/5 rounded-lg p-2 text-center">
                                            <div className={`text-[9px] font-bold uppercase mb-1 ${TOKEN_COLORS[tidx % TOKEN_COLORS.length]}`}>
                                                {ti.symbol}
                                            </div>
                                            <div className="text-sm font-mono text-white/90">{display}</div>
                                        </div>
                                    );
                                })}
                            </div>
                        </div>
                    );
                })}
            </div>
        </div>
    );
}
