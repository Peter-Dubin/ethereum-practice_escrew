import ConnectButton from "../components/ConnectButton";
import AddToken from "../components/AddToken";
import CreateOperation from "../components/CreateOperation";
import OperationsList from "../components/OperationsList";
import BalanceDebug from "../components/BalanceDebug";

export default function Home() {
  return (
    <main className="min-h-screen bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-zinc-900 via-zinc-950 to-black relative">
      <div className="absolute top-0 inset-x-0 h-[500px] bg-gradient-to-b from-indigo-500/10 to-transparent pointer-events-none" />

      <div className="max-w-[1440px] mx-auto px-6 pt-10 pb-20 relative z-10">
        <header className="flex justify-between items-center mb-16 bg-white/[0.02] p-4 rounded-3xl border border-white/5 backdrop-blur-md">
          <div className="flex items-center gap-4 pl-4">
            <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-indigo-500 via-purple-500 to-emerald-500 flex items-center justify-center text-white font-black text-xl shadow-lg shadow-purple-500/20 border-2 border-white/20">
              <>E</>
            </div>
            <div>
                <h1 className="text-2xl font-black bg-clip-text text-transparent bg-gradient-to-r from-white to-white/60 tracking-tight leading-none">
                  Escrow
                </h1>
                <p className="text-white/40 text-xs tracking-wider uppercase font-bold mt-1">Trustless P2P Swaps</p>
            </div>
          </div>
          <ConnectButton />
        </header>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
            <div className="lg:col-span-4">
               <AddToken />
               <CreateOperation />
            </div>
            <div className="lg:col-span-5 relative">
               <OperationsList />
            </div>
            <div className="lg:col-span-3">
               <BalanceDebug />
            </div>
        </div>
      </div>
    </main>
  );
}
