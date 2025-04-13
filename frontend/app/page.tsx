"use client";

import Navbar from "@/components/Navbar";
import LoginPage from "../components/LoginPage";
import UserDasboard from "./UserDashboard";
import Liquidations from "./Liquidations";
import { useAccount } from "wagmi";
import { useState } from "react";

export default function Home() {
  const { isConnected } = useAccount();

  const [isLoading, setIsLoading] = useState<boolean>(false);
  return (
    <>
      {isConnected ? (
        <div>
          <Navbar isLoading={isLoading} />{" "}
          <UserDasboard isLoading={isLoading} setIsLoading={setIsLoading} />{" "}
          {/* <Liquidations isLoading={isLoading} setIsLoading={setIsLoading} /> */}
        </div>
      ) : (
        <LoginPage />
      )}
    </>
  );
}
