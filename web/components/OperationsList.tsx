"use client";
import React, { useState, useEffect } from 'react';
import { Contract, formatUnits } from 'ethers';
import { useEthereum } from '../lib/ethereum';
import { ESCROW_ADDRESS } from '../lib/contracts';
import EscrowABI from '../lib/Escrow.json';
import ERC20ABI from '../lib/MockERC20.json';

const KNOWN_ACCOUNTS: Record<string, string> = {
    "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266": "Owner",
    "0x70997970c51812dc3a010c7d01b50e0d17dc79c8": "User 1",
    "0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc": "User 2",
};

export default function OperationsList() {
    const { signer, provider, account } = useEthereum();
    const [operations, setOperations] = useState<any[]>([]);
    const [loadingIds, setLoadingIds] = useState<Record<string, boolean>>({});
    const [tokenLabels, setTokenLabels] = useState<Record<string, string>>({});

    useEffect(() => {
        if (provider) fetchOps();
        const interval = setInterval(() => { if (provider) fetchOps() }, 5000);
        return () => clearInterval(interval);
    }, [provider, account]);

    const fetchOps = async () => {
        try {
            const escrow = new Contract(ESCROW_ADDRESS, EscrowABI.abi, provider);
            const [ops, tokens] = await Promise.all([
                escrow.getAllOperations(),
                escrow.getAllowedTokens(),
            ]);
            setOperations(ops || []);
            const labels: Record<string, string> = {};
            (tokens || []).forEach((t: string, i: number) => {
                labels[t.toLowerCase()] = `TOKEN ${String.fromCharCode(65 + i)}`;
            });
            setTokenLabels(labels);
        } catch (err) {
            console.error(err);
        }
    };

    const getTokenLabel = (addr: string) => tokenLabels[addr.toLowerCase()] ?? `${addr.slice(0, 6)}..`;
    const getCreatorLabel = (addr: string) => {
        const name = KNOWN_ACCOUNTS[addr.toLowerCase()];
        return `Creator: ${name ?? 'Unknown'} (${addr.slice(0, 6)}...${addr.slice(-4)})`;
    };

    const handleCancel = async (id: bigint) => {
        if (!signer) return;
        try {
            setLoadingIds({ ...loadingIds, [id.toString()]: true });
            const escrow = new Contract(ESCROW_ADDRESS, EscrowABI.abi, signer);
            const tx = await escrow.cancelOperation(id);
            await tx.wait();
            fetchOps();
        } catch (error: any) {
            alert("Error cancelling: " + (error.reason || error.message));
        } finally {
            setLoadingIds({ ...loadingIds, [id.toString()]: false });
        }
    };

    const handleComplete = async (id: bigint, tokenB: string, amountB: bigint) => {
        if (!signer) return;
        try {
            setLoadingIds({ ...loadingIds, [id.toString()]: true });
            const tokenContract = new Contract(tokenB, ERC20ABI.abi, signer);
            const txApprove = await tokenContract.approve(ESCROW_ADDRESS, amountB);
            await txApprove.wait();

            const escrow = new Contract(ESCROW_ADDRESS, EscrowABI.abi, signer);
            const txComplete = await escrow.completeOperation(id);
            await txComplete.wait();
            fetchOps();
        } catch (error: any) {
            alert("Error completing: " + (error.reason || error.message));
        } finally {
            setLoadingIds({ ...loadingIds, [id.toString()]: false });
        }
    };

    if (!account) return <div className="p-6 bg-white/5 rounded-2xl text-center text-white/50 border border-white/5">Please connect wallet to view operations.</div>;

    return (
        <div className="bg-white/[0.03] border border-white/10 rounded-2xl p-6 backdrop-blur-xl mb-6 shadow-2xl h-full">
            <div className="flex justify-between items-center mb-6">
                <h2 className="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-purple-400 to-pink-400">Operations Book</h2>
                <span className="px-3 py-1 bg-white/10 rounded-full text-xs font-bold text-white/70">{operations.length} Operations</span>
            </div>
            
            <div className="flex flex-col gap-4">
                {operations.length === 0 ? (
                    <p className="text-white/30 text-center py-10 italic">No available operations.</p>
                ) : (
                    operations.map((op, idx) => {
                        const isActive = op.status.toString() === "0";
                        const isCreator = op.creator.toLowerCase() === account.toLowerCase();
                        
                        let statusColor = "bg-emerald-500/20 text-emerald-400 border-emerald-500/30";
                        let statusText = "ACTIVE";
                        if (op.status.toString() === "1") { statusColor = "bg-blue-500/20 text-blue-400 border-blue-500/30"; statusText = "CLOSED"; }
                        if (op.status.toString() === "2") { statusColor = "bg-red-500/20 text-red-400 border-red-500/30"; statusText = "CANCELLED"; }

                        return (
                            <div key={idx} className="bg-black/30 border border-white/5 rounded-2xl p-5 relative overflow-hidden transition-all hover:bg-black/40">
                                <div className="flex justify-between items-start mb-4">
                                    <div className="flex items-center gap-2">
                                        <div className="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center text-white/50 font-bold text-xs border border-white/10">#{op.id.toString()}</div>
                                        <div className="text-xs text-white/40 font-mono">{getCreatorLabel(op.creator)}</div>
                                    </div>
                                    <div className={`px-2 py-1 rounded-md border text-[10px] font-bold tracking-widest ${statusColor}`}>
                                        {statusText}
                                    </div>
                                </div>
                                
                                <div className="flex items-center justify-between gap-4 mb-5">
                                    <div className="flex-1 text-center bg-white/5 rounded-xl border border-white/5 py-3">
                                        <div className="text-[10px] text-white/40 uppercase tracking-widest mb-1.5 font-bold">Offering</div>
                                        <div className="text-lg font-black text-emerald-300">{formatUnits(op.amountA, 18)}</div>
                                        <div className="text-xs font-bold text-white/40 mt-1 tracking-wide" title={op.tokenA}>{getTokenLabel(op.tokenA)}</div>
                                    </div>
                                    <svg className="w-5 h-5 text-white/20 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" /></svg>
                                    <div className="flex-1 text-center bg-white/5 rounded-xl border border-white/5 py-3">
                                        <div className="text-[10px] text-white/40 uppercase tracking-widest mb-1.5 font-bold">Requesting</div>
                                        <div className="text-lg font-black text-cyan-300">{formatUnits(op.amountB, 18)}</div>
                                        <div className="text-xs font-bold text-white/40 mt-1 tracking-wide" title={op.tokenB}>{getTokenLabel(op.tokenB)}</div>
                                    </div>
                                </div>

                                {isActive && (
                                    <div className="pt-2 border-t border-white/5">
                                        {isCreator ? (
                                            <button 
                                                onClick={() => handleCancel(op.id)}
                                                disabled={loadingIds[op.id.toString()]}
                                                className="w-full py-2.5 rounded-lg bg-red-500/10 hover:bg-red-500/20 text-red-400 font-bold text-sm border border-red-500/20 transition-colors disabled:opacity-50"
                                            >
                                                {loadingIds[op.id.toString()] ? "Cancelling..." : "Cancel Operation"}
                                            </button>
                                        ) : (
                                            <button 
                                                onClick={() => handleComplete(op.id, op.tokenB, op.amountB)}
                                                disabled={loadingIds[op.id.toString()]}
                                                className="w-full py-2.5 rounded-lg bg-gradient-to-r from-purple-500/20 to-pink-500/20 hover:from-purple-500/30 hover:to-pink-500/30 text-pink-300 font-bold text-sm border border-pink-500/30 transition-colors disabled:opacity-50"
                                            >
                                                {loadingIds[op.id.toString()] ? "Processing..." : "Complete Trade"}
                                            </button>
                                        )}
                                    </div>
                                )}
                            </div>
                        );
                    })
                )}
            </div>
        </div>
    );
}
