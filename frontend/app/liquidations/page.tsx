"use client";

import Navbar from "../../components/Navbar";
import LoginPage from "../../components/LoginPage";

import { useAccount } from "wagmi";
import { useState } from "react";

export default function Dashboard() {
  const { isConnected } = useAccount();

  const [isLoading, setIsLoading] = useState<boolean>(false);

  return (
    <>
      {isConnected ? (
        <div>
          <Navbar /> <p>This is the liquidation page</p>
        </div>
      ) : (
        <LoginPage />
      )}
    </>
  );
}
