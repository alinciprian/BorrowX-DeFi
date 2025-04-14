"use client";

import Navbar from "../../components/Navbar";
import LoginPage from "../../components/LoginPage";

import { useAccount } from "wagmi";
import { useState } from "react";
import Liquidations from "@/components/Liquidations";

export default function Dashboard() {
  const { isConnected } = useAccount();

  const [isLoading, setIsLoading] = useState<boolean>(false);

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
