"use client";
import React, { useState, useEffect, useRef } from 'react';
import { Contract, parseUnits } from 'ethers';
import { useEthereum } from '../lib/ethereum';
import { ESCROW_ADDRESS } from '../lib/contracts';
import EscrowABI from '../lib/Escrow.json';
import ERC20ABI from '../lib/MockERC20.json';

export default function CreateOperation() {
    const { signer, provider, account } = useEthereum();
    const [allowedTokens, setAllowedTokens] = useState<string[]>([]);
    const [tokenA, setTokenA] = useState("");
    const [tokenB, setTokenB] = useState("");
    const [amountA, setAmountA] = useState("");
    const [amountB, setAmountB] = useState("");
    const [loadingMap, setLoadingMap] = useState<Record<string, boolean>>({});
    const [openA, setOpenA] = useState(false);
    const [openB, setOpenB] = useState(false);
    const dropdownARef = useRef<HTMLDivElement>(null);
    const dropdownBRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        const handleClickOutside = (e: MouseEvent) => {
            if (dropdownARef.current && !dropdownARef.current.contains(e.target as Node)) setOpenA(false);
            if (dropdownBRef.current && !dropdownBRef.current.contains(e.target as Node)) setOpenB(false);
        };
        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    useEffect(() => {
        if (provider) fetchTokens();
        const interval = setInterval(() => { if (provider) fetchTokens() }, 10000);
        return () => clearInterval(interval);
    }, [provider, account]);

    const fetchTokens = async () => {
        try {
            const escrow = new Contract(ESCROW_ADDRESS, EscrowABI.abi, provider);
            const tokens = await escrow.getAllowedTokens();
            setAllowedTokens(tokens || []);
            if (tokens && tokens.length > 0 && !tokenA) {
                setTokenA(tokens[0]);
                setTokenB(tokens[1] || tokens[0]);
            }
        } catch (err) {}
    };

    const handleCreate = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!signer) return;
        try {
            setLoadingMap({ create: true });
            const parsedAmountA = parseUnits(amountA, 18);
            const parsedAmountB = parseUnits(amountB, 18);

            const tokenContract = new Contract(tokenA, ERC20ABI.abi, signer);
            const txApprove = await tokenContract.approve(ESCROW_ADDRESS, parsedAmountA);
            await txApprove.wait();

            const escrow = new Contract(ESCROW_ADDRESS, EscrowABI.abi, signer);
            const txCreate = await escrow.createOperation(tokenA, tokenB, parsedAmountA, parsedAmountB);
            await txCreate.wait();

            alert("Trade initialized globally!");
            setAmountA("");
            setAmountB("");
        } catch (error: any) {
            console.error(error);
            alert("Error: " + (error.reason || error.message));
        } finally {
            setLoadingMap({ create: false });
        }
    };

    const getTokenLabel = (addr: string) => {
        const idx = allowedTokens.findIndex(t => t.toLowerCase() === addr.toLowerCase());
        return idx >= 0 ? `TOKEN ${String.fromCharCode(65 + idx)}` : 'TOKEN ?';
    };
    const shortAddr = (addr: string) => addr ? `${addr.slice(0, 6)}...${addr.slice(-4)}` : '';

    const TokenDropdown = ({
        value, onChange, open, setOpen, dropdownRef, accentClass, focusClass
    }: {
        value: string;
        onChange: (v: string) => void;
        open: boolean;
        setOpen: (v: boolean) => void;
        dropdownRef: React.RefObject<HTMLDivElement | null>;
        accentClass: string;
        focusClass: string;
    }) => {
        const options = allowedTokens;
        return (
            <div ref={dropdownRef} className="relative mb-3">
                <button
                    type="button"
                    onClick={() => setOpen(!open)}
                    className={`w-full bg-black/40 border border-white/10 rounded-lg px-3 py-2 text-left outline-none transition-colors ${focusClass} flex items-center justify-between gap-2`}
                >
                    <div>
                        <div className={`text-xs font-bold ${accentClass}`}>{value ? getTokenLabel(value) : 'Select token'}</div>
                        {value && <div className="text-[10px] font-mono text-white/40 mt-0.5">{shortAddr(value)}</div>}
                    </div>
                    <svg className={`w-3 h-3 text-white/30 shrink-0 transition-transform ${open ? 'rotate-180' : ''}`} fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7" />
                    </svg>
                </button>
                {open && options.length > 0 && (
                    <div className="absolute z-50 w-full mt-1 bg-zinc-900 border border-white/10 rounded-lg overflow-hidden shadow-xl">
                        {options.map((t) => {
                            const globalIdx = allowedTokens.findIndex(a => a.toLowerCase() === t.toLowerCase());
                            const isSelected = t.toLowerCase() === value.toLowerCase();
                            return (
                                <div
                                    key={t}
                                    onClick={() => { onChange(t); setOpen(false); }}
                                    className={`px-3 py-2.5 cursor-pointer transition-colors hover:bg-white/10 ${isSelected ? 'bg-white/5' : ''}`}
                                >
                                    <div className={`text-xs font-bold ${accentClass}`}>TOKEN {String.fromCharCode(65 + globalIdx)}</div>
                                    <div className="text-[10px] font-mono text-white/40 mt-0.5">{shortAddr(t)}</div>
                                </div>
                            );
                        })}
                    </div>
                )}
            </div>
        );
    };

    if (!account) return <div className="p-6 bg-white/5 rounded-2xl text-center text-white/50 border border-white/5">Please connect wallet</div>;

    return (
        <div className="bg-white/[0.03] border border-white/10 rounded-2xl p-6 backdrop-blur-xl mb-6 shadow-2xl relative overflow-hidden">
            <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-emerald-500 via-teal-400 to-cyan-500"></div>

            <h2 className="text-xl font-bold mb-6 bg-clip-text text-transparent bg-gradient-to-r from-emerald-400 to-cyan-400">Launch New P2P Operation</h2>
            <form onSubmit={handleCreate} className="flex flex-col gap-5">
                <div className="grid grid-cols-2 gap-4">
                    <div className="bg-white/5 p-4 rounded-xl border border-white/5 hover:border-emerald-500/30 transition-colors">
                        <label className="block text-[10px] font-bold text-white/40 uppercase tracking-widest mb-3">YOU OFFLOAD</label>
                        <TokenDropdown
                            value={tokenA}
                            onChange={setTokenA}
                            open={openA}
                            setOpen={setOpenA}
                            dropdownRef={dropdownARef}
                            accentClass="text-emerald-400"
                            focusClass="hover:border-emerald-500/50"
                        />
                        <input
                            type="number" step="any" min="0"
                            value={amountA}
                            onChange={e => setAmountA(e.target.value)}
                            placeholder="Amount A"
                            className="w-full bg-black/40 border border-white/10 rounded-lg px-3 py-2 text-white/90 outline-none focus:border-emerald-500 text-lg placeholder:text-white/20"
                            required
                        />
                    </div>

                    <div className="bg-white/5 p-4 rounded-xl border border-white/5 hover:border-cyan-500/30 transition-colors relative">
                        <div className="absolute -left-5 top-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-zinc-900 border border-white/10 flex items-center justify-center text-white/30 z-10 hidden sm:flex">
                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" /></svg>
                        </div>
                        <label className="block text-[10px] font-bold text-white/40 uppercase tracking-widest mb-3">YOU ACQUIRE</label>
                        <TokenDropdown
                            value={tokenB}
                            onChange={setTokenB}
                            open={openB}
                            setOpen={setOpenB}
                            dropdownRef={dropdownBRef}
                            accentClass="text-cyan-400"
                            focusClass="hover:border-cyan-500/50"
                        />
                        <input
                            type="number" step="any" min="0"
                            value={amountB}
                            onChange={e => setAmountB(e.target.value)}
                            placeholder="Amount B"
                            className="w-full bg-black/40 border border-white/10 rounded-lg px-3 py-2 text-white/90 outline-none focus:border-cyan-500 text-lg placeholder:text-white/20"
                            required
                        />
                    </div>
                </div>

                {tokenA && tokenB && tokenA.toLowerCase() === tokenB.toLowerCase() && (
                    <div className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-amber-500/10 border border-amber-500/30 text-amber-400 text-xs font-bold">
                        <svg className="w-4 h-4 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" /></svg>
                        You cannot offload and acquire the same token. Please select two different tokens.
                    </div>
                )}
                <button
                    disabled={loadingMap.create || allowedTokens.length === 0 || (tokenA.toLowerCase() === tokenB.toLowerCase())}
                    className="w-full py-3.5 rounded-xl bg-gradient-to-r from-emerald-500 hover:from-emerald-400 to-cyan-600 hover:to-cyan-500 text-white font-bold shadow-lg shadow-emerald-500/20 active:scale-[0.98] transition-all disabled:opacity-50 disabled:grayscale"
                >
                    {loadingMap.create ? "Authorizing & Broadcasting..." : "Submit Transaction"}
                </button>
            </form>
        </div>
    );
}
