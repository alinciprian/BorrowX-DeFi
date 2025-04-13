"use client";
import * as React from "react";
import WithdrawForm from "../../components/WithdrawForm";
import DepositForm from "../../components/DepositForm";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { useAccount } from "wagmi";
import { getBalance, readContract } from "@wagmi/core";
import { wagmiConfig } from "../../components/Providers";
import { useState, useEffect } from "react";
import { BorrowXABI } from "../../config/BorrowXABI";
import { BorrowXAddress } from "@/lib/constants";
import { xUSDCAddress } from "@/lib/constants";
import { formatUnits, parseUnits } from "viem";
import BorrowForm from "../../components/BorrowForm";
import { BalanceType } from "@/lib/utils";
import UserStats from "../../components/UserStats";
import PayDebt from "../../components/PayDebt";

export default function Dashboard({
  isLoading,
  setIsLoading,
}: {
  isLoading: boolean;
  setIsLoading: React.Dispatch<React.SetStateAction<boolean>>;
}) {
  const { address, isConnected } = useAccount();
  const [collateral, setCollateral] = useState<BalanceType | null>(null);
  const [borrowed, setBorrowed] = useState<BalanceType | null>(null);
  const [borrowAllowance, setBorrowAllowance] = useState<BalanceType | null>(
    null
  );
  const [withdrawAllowance, setWithdrawAllowance] =
    useState<BalanceType | null>(null);
  const [xusdcBalance, setxusdcBalance] = useState<BalanceType | null>(null);
  const [netWorth, setNetworth] = useState<BalanceType | null>(null);
  const [usdValueOfCollateral, setUsdValueOfCollateral] =
    useState<BalanceType | null>(null);

  //////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////READ FROM CONTRACT/////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////

  /// This function is used get the xUSDC balance of the
  async function fetchxUSDCBalance() {
    try {
      const balancexUSDC = await getBalance(wagmiConfig, {
        address: address!,
        token: xUSDCAddress,
      });

      setxusdcBalance(balancexUSDC);
    } catch (error) {
      console.log("Error fetching xUSDC balance:", error);
    }
  }

  /// This function is used to read the amount of collateral deposited from contract
  async function fetchUserCollateralDeposited(address: `0x${string}`) {
    try {
      const result = await readContract(wagmiConfig, {
        abi: BorrowXABI,
        address: BorrowXAddress,
        functionName: "getUserCollateralDeposited",
        args: [address],
      });

      setCollateral({
        formatted: formatUnits(result as bigint, 18),
        symbol: "ETH",
      });
    } catch (error) {
      console.log(error);
      setIsLoading(false);
    }
  }

  /// This function is used to read the amount of xUSDC borrowed by the user
  async function fetchUserBorrowAmount(address: `0x${string}`) {
    try {
      const result = await readContract(wagmiConfig, {
        abi: BorrowXABI,
        address: BorrowXAddress,
        functionName: "getUserMintedXUSDC",
        args: [address],
      });
      setBorrowed({
        formatted: formatUnits(result as bigint, 18),
        symbol: "xUSDC",
      });
    } catch (error) {
      console.log(error);
    }
  }

  /// This function is used to read the amount of xUSDC an user is allowed to mint
  async function fetchUserBorrowAllowance(address: `0x${string}`) {
    try {
      const result: bigint = (await readContract(wagmiConfig, {
        abi: BorrowXABI,
        address: BorrowXAddress,
        functionName: "getMintAmountAllowed",
        args: [address],
      })) as bigint;
      setBorrowAllowance({
        formatted: formatUnits(result as bigint, 18),
        symbol: "xUSDC",
      });
    } catch (error) {
      console.log(error);
    }
  }

  /// This function is used to read the amount of collateral an user is allowed to withdraw given current debt
  async function fetchUserWithdrawalAllowance(address: `0x${string}`) {
    try {
      const result: bigint = (await readContract(wagmiConfig, {
        abi: BorrowXABI,
        address: BorrowXAddress,
        functionName: "getWithdrawAmountAllowed",
        args: [address],
      })) as bigint;
      setWithdrawAllowance({
        formatted: formatUnits(result as bigint, 18),
        symbol: "ETH",
      });
    } catch (error) {
      console.log(error);
    }
  }

  /// This function is used to compute the USD value of the collateral deposited
  async function fetchUsdValueOfUserCollateral(address: `0x${string}`) {
    try {
      const result = await readContract(wagmiConfig, {
        abi: BorrowXABI,
        address: BorrowXAddress,
        functionName: "getUsdValueOfUserCollateral",
        args: [address],
      });
      setUsdValueOfCollateral({
        formatted: formatUnits(result as bigint, 18),
        symbol: "USD",
      });
    } catch (error) {
      console.log(error);
    }
  }

  function computeNetWorth() {
    const result =
      parseUnits(usdValueOfCollateral!.formatted, 18) +
      parseUnits(xusdcBalance!.formatted, 18) -
      parseUnits(borrowed!.formatted, 18);

    setNetworth({
      formatted: formatUnits(result as bigint, 18),
      symbol: "USD",
    });
  }

  const fetchUserData = async () => {
    //setIsLoading(true);
    await Promise.all([
      fetchxUSDCBalance(),
      fetchUserBorrowAllowance(address!),
      fetchUserBorrowAmount(address!),
      fetchUserCollateralDeposited(address!),
      fetchUserWithdrawalAllowance(address!),
      fetchUsdValueOfUserCollateral(address!),
      fetchUserPosition(),
    ]);
    setIsLoading(false);
  };

  const fetchUserPosition = async () => {
    const endpoint = "http://localhost:8080/v1/graphql";
    const headers = {
      "content-type": "application/json",
    };
    const graphqlQuery = {
      query: `query UserPosition {
        Position {
          id
          borrowed
          collateral
          account
          timestamp
          txHash
        }
      }`,
    };

    const options = {
      method: "POST",
      headers: headers,
      body: JSON.stringify(graphqlQuery),
    };

    const response = await fetch(endpoint, options);
    const data = await response.json();

    const position = data.data.Position;
    console.log(position); // data
  };

  useEffect(() => {
    if (usdValueOfCollateral && xusdcBalance && borrowed) {
      computeNetWorth();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [usdValueOfCollateral, xusdcBalance, borrowed]);

  useEffect(() => {
    if (isConnected) {
      fetchUserData();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isConnected]);

  // The value of collateral + balance of xUSDC - debt

  return (
    <div className="flex items-center justify-center min-h-screen bg-black">
      {/* Center the grid container */}
      <div className="relative">
        {/* Absolute positioning removed from the inner content, and centralized */}
        <div className="absolute -top-10 left-0 text-[10px] font-semibold">
          <p className="text-gray-400">Net worth:</p>
          <div className="flex items-center text-white">
            <p className="text-gray-400">$ </p>
            <p> {netWorth?.formatted}</p>
          </div>
        </div>

        {/* Centered card */}
        <Card className="w-[400px] bg-gray-800 text-white">
          <CardHeader>
            <CardTitle>Your stats</CardTitle>
          </CardHeader>
          <CardContent></CardContent>
        </Card>
      </div>
    </div>
  );
}
