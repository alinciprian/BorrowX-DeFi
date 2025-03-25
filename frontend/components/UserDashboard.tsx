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
import { InputWithButton } from "./InputWithButton";
import { metisGoerli } from "wagmi/chains";

export default function Dashboard() {
  const { address, isConnected } = useAccount();
  const { disconnect } = useDisconnect();

  const [userCollateral, setUserCollateral] = useState<BalanceType | null>(
    null
  );

  const PRECISION = 10 ** 18;

  type BalanceType = {
    formatted: string;
    symbol: string;
  };

  /// This function is used to read the amount of collateral deposited from contract
  async function fetchUserCollateralDeposited(address: `0x${string}`) {
    const result: bigint = (await readContract(wagmiConfig, {
      abi: BorrowXABI,
      address: "0x52838b5A0ee375618824236c8d03e78d34DE0Adb",
      functionName: "getUserCollateralDeposited",
      args: [address],
    })) as bigint;
    setUserCollateral({
      formatted: (Number(result) / 10 ** 18).toFixed(4), // Convert `bigint` to string with 4 decimals
      symbol: "ETH",
    });
  }

  useEffect(() => {
    if (isConnected) {
      fetchUserCollateralDeposited(address!);
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
          <CardContent>
            {Number(userCollateral!.formatted) > 0 ? (
              <p>
                {userCollateral!.formatted} {userCollateral!.symbol}
              </p>
            ) : (
              <p className="text-[10px] text-gray-400">
                No collateral deposited yet
              </p>
            )}
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
          <CardContent className="flex w-full max-w-sm items-center space-x-2">
            <Input />
            <Button>Deposit</Button>
          </CardContent>
        </Card>

        <Card className="w-[400px] bg-gray-800 text-white">
          <CardHeader>
            <CardTitle>Borrow xUSDC</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-[10px] text-gray-400">
              Insufficient collateral deposited
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
