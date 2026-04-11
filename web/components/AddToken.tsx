"use client";
import React, { useState, useEffect } from 'react';
import { Contract, ContractFactory, parseUnits } from 'ethers';
import MockERC20ABI from '../lib/MockERC20.json';
import { useEthereum } from '../lib/ethereum';
import { ESCROW_ADDRESS } from '../lib/contracts';
import EscrowABI from '../lib/Escrow.json';

export default function AddToken() {
    const { signer, provider, account } = useEthereum();
    const [tokenAddress, setTokenAddress] = useState("");
    const [allowedTokens, setAllowedTokens] = useState<string[]>([]);
    const [isOwner, setIsOwner] = useState(false);
    const [loading, setLoading] = useState(false);
    const [tokenName, setTokenName] = useState("");
    const [tokenSymbol, setTokenSymbol] = useState("");
    const [deploying, setDeploying] = useState(false);
    const [lastDeployed, setLastDeployed] = useState<string | null>(null);

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

    const handleDeploy = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!signer) return;
        const TEST_ACCOUNTS = [
            "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
            "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
            "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
        ];
        try {
            setDeploying(true);
            const factory = new ContractFactory(MockERC20ABI.abi, (MockERC20ABI as any).bytecode, signer);
            const newToken = await factory.deploy(tokenName, tokenSymbol);
            await newToken.waitForDeployment();
            const newTokenAddress = await newToken.getAddress();

            for (const addr of TEST_ACCOUNTS) {
                const tx = await (newToken as any).mint(addr, parseUnits("1000", 18));
                await tx.wait();
            }

            const escrow = new Contract(ESCROW_ADDRESS, EscrowABI.abi, signer);
            const txAdd = await escrow.addToken(newTokenAddress);
            await txAdd.wait();

            setLastDeployed(newTokenAddress);
            setTokenName("");
            setTokenSymbol("");
            await checkOwnerAndTokens();
        } catch (error: any) {
            console.error(error);
            alert("Deploy error: " + (error.reason || error.message));
        } finally {
            setDeploying(false);
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

            <div className="border-t border-white/5 pt-5 mb-6 relative z-10">
                <h3 className="text-xs font-semibold text-white/40 mb-3 uppercase tracking-wider">Deploy New Test Token</h3>
                <form onSubmit={handleDeploy} className="flex gap-2 flex-wrap">
                    <input
                        type="text"
                        value={tokenName}
                        onChange={e => setTokenName(e.target.value)}
                        placeholder="Token Name (e.g. Token C)"
                        className="flex-1 min-w-[140px] bg-black/40 border border-white/10 rounded-xl px-4 py-2 text-white/90 outline-none focus:border-violet-500 transition-colors text-sm"
                        required
                    />
                    <input
                        type="text"
                        value={tokenSymbol}
                        onChange={e => setTokenSymbol(e.target.value)}
                        placeholder="Symbol (e.g. TKC)"
                        className="w-32 bg-black/40 border border-white/10 rounded-xl px-4 py-2 text-white/90 outline-none focus:border-violet-500 transition-colors text-sm"
                        required
                    />
                    <button
                        disabled={deploying}
                        className="px-5 py-2 rounded-xl bg-violet-500/20 hover:bg-violet-500/40 text-violet-300 font-semibold border border-violet-500/40 transition-all disabled:opacity-50 text-sm"
                    >
                        {deploying ? "Deploying..." : "Deploy & Register"}
                    </button>
                </form>
                {lastDeployed && (
                    <div className="mt-2 text-[10px] font-mono text-violet-300/70">
                        Deployed: {lastDeployed}
                    </div>
                )}
            </div>

            <div className="relative z-10">
                <h3 className="text-xs font-semibold text-white/40 mb-3 uppercase tracking-wider">Approved Registry</h3>
                {allowedTokens.length === 0 ? (
                    <p className="text-white/30 text-sm italic">No tokens found.</p>
                ) : (
                    <div className="flex flex-col gap-2">
                        {allowedTokens.map((token, idx) => (
                            <div key={idx} className="flex items-center gap-3 bg-white/5 px-4 py-2.5 rounded-xl border border-white/5 hover:bg-white/10 transition-colors">
                                <div className="w-2 h-2 rounded-full bg-blue-400 shadow-[0_0_8px_rgba(96,165,250,0.8)] shrink-0"></div>
                                <div>
                                    <div className="text-xs font-bold text-blue-300 tracking-wide">TOKEN {String.fromCharCode(65 + idx)}</div>
                                    <div className="font-mono text-[10px] text-white/40 mt-0.5">{token}</div>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
}
