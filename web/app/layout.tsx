import type { Metadata } from "next";
import "./globals.css";
import { EthereumProvider } from "../lib/ethereum";

export const metadata: Metadata = {
  title: "Escrow DApp",
  description: "Web3 Escrow Token Swaps",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="bg-zinc-950 text-white min-h-screen font-sans">
        <EthereumProvider>
          {children}
        </EthereumProvider>
      </body>
    </html>
  );
}
