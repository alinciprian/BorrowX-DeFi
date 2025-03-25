import Balance from "../components/Balance";
import * as React from "react";

import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
  CardContent,
} from "@/components/ui/card";
import { usePrivy, useWallets } from "@privy-io/react-auth";
import { useAccount, useDisconnect } from "wagmi";
import {
  getBalance,
  waitForTransactionReceipt,
  readContract,
  writeContract,
} from "@wagmi/core";
import { wagmiConfig } from "../components/Providers";
import { useState, useEffect } from "react";
import { BorrowXABI } from "../config/BorrowXABI";
import { xusdcABI } from "../config/xusdcABI";

export default function Dashboard() {
  const { address, isConnected } = useAccount();
  const { disconnect } = useDisconnect();

  const [balanceSTK, setBalanceSTK] = useState<BalanceType | null>(null);
  const [balancedUSDC, setBalancedUSDC] = useState<BalanceType | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [stakingAmount, setStakingAmount] = useState<number>(0);
  const [withdrawAmount, setWithdrawAmount] = useState<number>(0);
  const [amountstaked, setAmountStaked] = useState<bigint>(0n);
  const [rewardAmount, setRewardAmount] = useState<bigint>(0n);

  const PRECISION = 10 ** 18;

  type BalanceType = {
    formatted: string;
    symbol: string;
  };

  function handleMax() {
    setWithdrawAmount(Number(amountstaked) / PRECISION);
  }

  useEffect(() => {
    if (isConnected) {
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isConnected]);

  return (
    <div className="flex flex-col items-center justify-center h-screen bg-black text-white relative">
      <div className="grid grid-cols-2 gap-2 scale-150 relative">
        {/* User Balance - Positioned Above the First Card */}
        <div className="absolute -top-15 left-2 text-[10px] font-semibold">
          <p className="text-gray-400">Net worth:</p>
          <p className="flex items-center text-white">
            <p className="text-gray-400">$ </p>
            <p>0</p>
          </p>
        </div>

        <Card className="w-[400px] bg-gray-800 text-white">
          <CardHeader>
            <CardTitle>Collateral Info</CardTitle>
          </CardHeader>
          <CardContent className="text-[10px] text-gray-400">
            No collateral deposited yet
          </CardContent>
        </Card>

        <Card className="w-[400px] bg-gray-800 text-white">
          <CardHeader>
            <CardTitle> Your borrows </CardTitle>
          </CardHeader>
          <CardContent className="text-[10px] text-gray-400">
            Nothing borrowed yet
          </CardContent>
        </Card>

        <Card className="w-[400px] bg-gray-800 text-white">
          <CardHeader>
            <CardTitle>Deposit Collateral</CardTitle>
          </CardHeader>
          <CardContent></CardContent>
        </Card>

        <Card className="w-[400px] bg-gray-800 text-white">
          <CardHeader>
            <CardTitle>Borrow xUSDC</CardTitle>
          </CardHeader>
          <CardContent></CardContent>
        </Card>
      </div>
    </div>
  );
}
