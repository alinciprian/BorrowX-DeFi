"use client";

import Navbar from "../../components/Navbar";
import LoginPage from "../../components/LoginPage";

import { useAccount } from "wagmi";
import Liquidations from "@/components/Liquidations";

export default function Dashboard() {
  const { isConnected } = useAccount();

  return (
    <>
      {isConnected ? (
        <div>
          <Navbar /> <Liquidations />
        </div>
      ) : (
        <LoginPage />
      )}
    </>
  );
}
