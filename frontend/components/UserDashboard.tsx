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

  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [collateral, setCollateral] = useState<BalanceType | null>(null);
  const [borrowed, setBorrowed] = useState<BalanceType | null>(null);
  const [borrowAllowance, setBorrowAllowance] = useState<BalanceType | null>(
    null
  );
  const [withdrawAllowance, setWithdrawAllowance] =
    useState<BalanceType | null>(null);

  const PRECISION = 10 ** 18;

  type BalanceType = {
    formatted: string;
    symbol: string;
  };

  //////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////READ FROM CONTRACT/////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////

  /// This function is used to read the amount of collateral deposited from contract
  async function fetchUserCollateralDeposited(address: `0x${string}`) {
    const result: bigint = (await readContract(wagmiConfig, {
      abi: BorrowXABI,
      address: "0x52838b5A0ee375618824236c8d03e78d34DE0Adb",
      functionName: "getUserCollateralDeposited",
      args: [address],
    })) as bigint;
    setCollateral({
      formatted: (Number(result) / 10 ** 18).toFixed(4), // Convert `bigint` to string with 4 decimals
      symbol: "ETH",
    });
  }

  /// This function is used to read the amount of xUSDC borrowed by the user
  async function fetchUserBorrowAmount(address: `0x${string}`) {
    const result: bigint = (await readContract(wagmiConfig, {
      abi: BorrowXABI,
      address: "0x52838b5A0ee375618824236c8d03e78d34DE0Adb",
      functionName: "getUserMintedXUSDC",
      args: [address],
    })) as bigint;
    setBorrowed({
      formatted: (Number(result) / 10 ** 18).toFixed(4), // Convert `bigint` to string with 4 decimals
      symbol: "xUSDC",
    });
  }

  /// This function is used to read the amount of xUSDC an user is allowed to mint
  async function fetchUserBorrowAllowance(address: `0x${string}`) {
    const result: bigint = (await readContract(wagmiConfig, {
      abi: BorrowXABI,
      address: "0x52838b5A0ee375618824236c8d03e78d34DE0Adb",
      functionName: "getMintAmountAllowed",
      args: [address],
    })) as bigint;
    setBorrowAllowance({
      formatted: (Number(result) / 10 ** 18).toFixed(4), // Convert `bigint` to string with 4 decimals
      symbol: "xUSDC",
    });
  }

  /// This function is used to read the amount of collateral an user is allowed to withdraw given current debt
  async function fetchUserWithdrawalAllowance(address: `0x${string}`) {
    const result: bigint = (await readContract(wagmiConfig, {
      abi: BorrowXABI,
      address: "0x52838b5A0ee375618824236c8d03e78d34DE0Adb",
      functionName: "getWithdrawAmountAllowed",
      args: [address],
    })) as bigint;
    setWithdrawAllowance({
      formatted: (Number(result) / 10 ** 18).toFixed(4), // Convert `bigint` to string with 4 decimals
      symbol: "ETH",
    });
  }

  const fetchUserData = async () => {
    setIsLoading(true);
    await Promise.all([
      fetchUserBorrowAllowance(address!),
      fetchUserBorrowAmount(address!),
      fetchUserCollateralDeposited(address!),
      fetchUserWithdrawalAllowance(address!),
    ]);
    setIsLoading(false);
  };

  useEffect(() => {
    if (isConnected) {
      fetchUserData();
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
            {
              <p className="text-[10px] text-gray-400">
                {collateral?.formatted} {collateral?.symbol}
              </p>
            }
          </CardContent>
        </Card>

        <Card className="w-[400px] bg-gray-800 text-white">
          <CardHeader>
            <CardTitle> Manage debt </CardTitle>
          </CardHeader>
          <CardContent className="text-[10px] text-gray-400">
            <p className="mb-1">
              Your current debt: {borrowed?.formatted} {borrowed?.symbol}.
            </p>

            <p className="flex w-full max-w-sm items-center space-x-2">
              <Input type="text" />
              <Button>Pay debt</Button>
              <Button>Max</Button>
            </p>
            <p className="mt-1 flex w-full max-w-sm items-center space-x-2">
              <p>
                Close position if you wish to pay the entire debt amount and
                withdraw all collateral.
              </p>
              <Button>Close Position</Button>
            </p>
          </CardContent>
        </Card>

        <Card className="w-[400px] bg-gray-800 text-white">
          <CardHeader>
            <CardTitle>Collateral management</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="mb-1 flex w-full max-w-sm items-center space-x-2">
              <Input />
              <Button>Deposit</Button>
            </p>

            <p className="flex w-full max-w-sm items-center space-x-2">
              <Input />
              <Button>Withdraw</Button>
              <Button>Max</Button>
            </p>
            <p className=" mb-1 text-[10px] text-gray-400">
              You can withdraw {withdrawAllowance?.formatted}{" "}
              {withdrawAllowance?.symbol}.
            </p>
          </CardContent>
        </Card>

        <Card className="w-[400px] bg-gray-800 text-white">
          <CardHeader>
            <CardTitle>Borrow xUSDC</CardTitle>
          </CardHeader>
          <CardContent>
            <p className=" mb-1 text-[10px] text-gray-400">
              You can currently borrow {borrowAllowance?.formatted}{" "}
              {borrowAllowance?.symbol}.
            </p>
            <p className="flex w-full max-w-sm items-center space-x-2">
              <Input />
              <Button>Borrow</Button>
              <Button>Max</Button>
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
