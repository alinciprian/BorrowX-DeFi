import Balance from "../components/Balance";
import * as React from "react";
import WithdrawForm from "./WithdrawForm";
import DepositForm from "./DepositForm";
import {
  Card,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
  CardContent,
} from "@/components/ui/card";
import { useAccount } from "wagmi";
import { getBalance, readContract } from "@wagmi/core";
import { wagmiConfig } from "../components/Providers";
import { useState, useEffect } from "react";
import { BorrowXABI } from "../config/BorrowXABI";
import { BorrowXAddress } from "@/lib/constants";
import { xUSDCAddress } from "@/lib/constants";
import { formatUnits } from "viem";
import BorrowForm from "./BorrowForm";
import { BalanceType } from "@/lib/utils";
import UserStats from "./UserStats";
import PayDebt from "./PayDebt";

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
      console.log(result);
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

  const fetchUserData = async () => {
    //setIsLoading(true);
    await Promise.all([
      fetchxUSDCBalance(),
      fetchUserBorrowAllowance(address!),
      fetchUserBorrowAmount(address!),
      fetchUserCollateralDeposited(address!),
      fetchUserWithdrawalAllowance(address!),
    ]);
    setIsLoading(false);
  };

  //////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////Write to contract//////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////

  useEffect(() => {
    if (isConnected) {
      fetchUserData();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isConnected]);

  return (
    <div>
      <div className="flex flex-col items-center justify-center h-screen bg-black text-white relative">
        <div className="grid grid-cols-2 gap-2 scale-150 relative">
          <div className="absolute -top-15 left-2 text-[10px] font-semibold">
            <p className="text-gray-400">Net worth:</p>
            <div className="flex items-center text-white">
              <p className="text-gray-400">$</p>
              <p></p>
            </div>
          </div>

          <Card className="w-[400px] bg-gray-800 text-white">
            <CardHeader>
              <CardTitle>Your stats</CardTitle>
            </CardHeader>
            <CardContent>
              <UserStats collateral={collateral} xusdcBalance={xusdcBalance} />
            </CardContent>
          </Card>

          <Card className="w-[400px] bg-gray-800 text-white">
            <CardHeader>
              <CardTitle> Manage debt </CardTitle>
            </CardHeader>
            <CardContent className="text-[10px] text-gray-400">
              <PayDebt
                setIsLoading={setIsLoading}
                isLoading={isLoading}
                onfetchUserData={fetchUserData}
                borrowed={borrowed}
              />
            </CardContent>
          </Card>

          <Card className="w-[400px] bg-gray-800 text-white">
            <CardHeader>
              <CardTitle>Collateral management</CardTitle>
            </CardHeader>
            <CardContent>
              <DepositForm
                setIsLoading={setIsLoading}
                isLoading={isLoading}
                onfetchUserData={fetchUserData}
              />

              <WithdrawForm
                setIsLoading={setIsLoading}
                isLoading={isLoading}
                onfetchUserData={fetchUserData}
                withdrawAllowance={withdrawAllowance}
              />
            </CardContent>
          </Card>

          <Card className="w-[400px] bg-gray-800 text-white">
            <CardHeader>
              <CardTitle>Borrow xUSDC</CardTitle>
            </CardHeader>
            <CardContent>
              <BorrowForm
                setIsLoading={setIsLoading}
                isLoading={isLoading}
                onfetchUserData={fetchUserData}
                borrowAllowance={borrowAllowance}
              />
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
