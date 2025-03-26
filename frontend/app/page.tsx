"use client";

import Navbar from "@/components/Navbar";
import LoginPage from "../components/LoginPage";
import UserDasboard from "../components/UserDashboard";
import { useAccount } from "wagmi";

export default function Home() {
  const { isConnected } = useAccount();
  return (
    <>
      {isConnected ? (
        <div>
          <Navbar /> <UserDasboard />{" "}
        </div>
      ) : (
        <LoginPage />
      )}
    </>
  );
}
