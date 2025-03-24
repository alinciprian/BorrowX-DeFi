"use client";

import LoginPage from "../components/LoginPage";
import { useAccount } from "wagmi";

export default function Home() {
  const { isConnected } = useAccount();
  return (
    <>
      <LoginPage />
    </>
  );
}
