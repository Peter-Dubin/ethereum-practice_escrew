"use client";
import React, { useState, useEffect } from 'react';
import { Contract } from 'ethers';
import { useEthereum } from '../lib/ethereum';
import { ESCROW_ADDRESS } from '../lib/contracts';
import EscrowABI from '../lib/Escrow.json';

export default function AddToken() {
    const { signer, provider, account } = useEthereum();
    const [tokenAddress, setTokenAddress] = useState("");
    const [allowedTokens, setAllowedTokens] = useState<string[]>([]);
    const [isOwner, setIsOwner] = useState(false);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        if (provider) checkOwnerAndTokens();
        const interval = setInterval(() => { if (provider) checkOwnerAndTokens(); }, 15000);
        return () => clearInterval(interval);
    }, [provider, account]);

    const checkOwnerAndTokens = async () => {
        if (!provider || !ESCROW_ADDRESS) return;
        try {
            const escrow = new Contract(ESCROW_ADDRESS, EscrowABI.abi, provider);
            
            // Try to get owner, gracefully handle failures if contract isn't proper
            try {
                const owner = await escrow.owner();
                setIsOwner(account !== null && owner.toLowerCase() === account.toLowerCase());
            } catch (e) {
                console.error("Not owner or error", e);
            }

            try {
                const tokens = await escrow.getAllowedTokens();
                setAllowedTokens(tokens || []);
            } catch (err) {
                setAllowedTokens([]);
            }
        } catch (error) {
            console.error("Error setting up contract:", error);
        }
    };

    const handleAdd = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!signer) return;
        try {
            setLoading(true);
            const escrow = new Contract(ESCROW_ADDRESS, EscrowABI.abi, signer);
            const tx = await escrow.addToken(tokenAddress);
            await tx.wait();
            setTokenAddress("");
            await checkOwnerAndTokens();
            alert("Token added successfully!");
        } catch (error: any) {
            console.error(error);
            alert("Error: " + (error.reason || error.message));
        } finally {
            setLoading(false);
        }
    };

    if (!isOwner) return null; // Admin only

    return (
        <div className="bg-white/[0.03] border border-white/10 rounded-2xl p-6 backdrop-blur-xl mb-6 shadow-2xl overflow-hidden relative">
            <div className="absolute top-0 right-0 p-3 opacity-20 pointer-events-none">
                <svg className="w-24 h-24 text-blue-400" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2L2 7l10 5 10-5-10-5zm0 15L2 12v2l10 5 10-5v-2l-10 5zm0-4.5L2 9.5v2l10 5 10-5v-2l-10 3z"/></svg>
            </div>
            
            <h2 className="text-xl font-bold mb-4 bg-clip-text text-transparent bg-gradient-to-r from-blue-400 to-indigo-400 relative z-10">Add Allowed Token (Admin)</h2>
            <form onSubmit={handleAdd} className="flex gap-3 mb-6 relative z-10">
                <input 
                    type="text" 
                    value={tokenAddress} 
                    onChange={e => setTokenAddress(e.target.value)} 
                    placeholder="ERC20 Address 0x..." 
                    className="flex-1 bg-black/40 border border-white/10 rounded-xl px-4 py-2 text-white/90 outline-none focus:border-indigo-500 transition-colors font-mono text-sm"
                    required 
                />
                <button 
                    disabled={loading} 
                    className="px-6 py-2 rounded-xl bg-indigo-500/20 hover:bg-indigo-500/40 text-indigo-300 font-semibold border border-indigo-500/40 transition-all disabled:opacity-50"
                >
                    {loading ? "Wait..." : "Add"}
                </button>
            </form>

            <div className="relative z-10">
                <h3 className="text-xs font-semibold text-white/40 mb-3 uppercase tracking-wider">Approved Registry</h3>
                {allowedTokens.length === 0 ? (
                    <p className="text-white/30 text-sm italic">No tokens found.</p>
                ) : (
                    <div className="flex flex-col gap-2">
                        {allowedTokens.map((token, idx) => (
                            <div key={idx} className="flex items-center gap-3 bg-white/5 px-4 py-2.5 rounded-xl border border-white/5 hover:bg-white/10 transition-colors">
                                <div className="w-2 h-2 rounded-full bg-blue-400 shadow-[0_0_8px_rgba(96,165,250,0.8)]"></div>
                                <span className="font-mono text-sm text-blue-100">{token}</span>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
}
