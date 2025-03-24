"use client";

import { useAccount, useDisconnect } from "wagmi";
import { usePrivy, useWallets } from "@privy-io/react-auth";
import { useSetActiveWallet } from "@privy-io/wagmi";
import Balance from "../components/Balance";

import wagmiPrivyLogo from "../public/wagmi_privy_logo.png";

const MonoLabel = ({ label }: { label: string }) => {
  return (
    <span className="rounded-xl bg-slate-200 px-2 py-1 font-mono">{label}</span>
  );
};

export default function Home() {
  // Privy hooks
  const {
    ready,
    user,
    authenticated,
    login,
    connectWallet,
    logout,
    linkWallet,
  } = usePrivy();

  const { wallets, ready: walletsReady } = useWallets();

  // WAGMI hooks
  const { address, isConnected, isConnecting, isDisconnected } = useAccount();
  const { disconnect } = useDisconnect();
  const { setActiveWallet } = useSetActiveWallet();

  if (!ready) {
    return null;
  }

  return (
    <div>
      <Balance />
    </div>
  );
}
