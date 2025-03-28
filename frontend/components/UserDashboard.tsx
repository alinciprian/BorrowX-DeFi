import Balance from "../components/Balance";
import * as React from "react";

import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import WithdrawForm from "./WithdrawForm";
import {
  Card,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
  CardContent,
} from "@/components/ui/card";

import { useAccount } from "wagmi";
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
import { z } from "zod";
import { useForm, SubmitHandler } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { formatUnits, parseUnits } from "viem";

type BalanceType = {
  formatted: string;
  symbol: string;
};

const DepositSchema = z.object({
  amountDeposit: z.number().positive("Input must be greater than 0"),
});
type DepositSchemaType = z.infer<typeof DepositSchema>;

// const PayDebtSchema = z.object({
//   amountPayDebt: z.number().positive("Input must be greater than 0"),
// });
// type PayDebtSchemaType = z.infer<typeof PayDebtSchema>;

// const BorrowSchema = z.object({
//   amountBorrow: z.number().positive("Input must be greater than 0"),
// });
// type BorrowSchemaType = z.infer<typeof BorrowSchema>;

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

  /*   const [inputCollateral, setInputCollateral] = useState<number>(0); */

  const [inputBorrow, setInputBorrow] = useState<number>(0);
  const [inputPayDebt, setInputPayDebt] = useState<number>(0);

  const {
    register: registerDeposit,
    handleSubmit: handleSubmitDeposit,
    formState: { errors: errorsDeposit },
    watch,
  } = useForm<DepositSchemaType>({ resolver: zodResolver(DepositSchema) });

  const _amount = watch("amountDeposit");
  console.log(_amount);

  const PRECISION = 10 ** 18;

  //////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////READ FROM CONTRACT/////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////

  /// This function is used get the xUSDC balance of the
  async function fetchxUSDCBalance() {
    try {
      const balancexUSDC = await getBalance(wagmiConfig, {
        address: address!,
        token: "0xBEed2827e2cb03ea4B4d4DA8A1CF8638D9CeCA27",
      });

      setxusdcBalance(balancexUSDC);
    } catch (error) {
      console.log("Error fetching xUSDC balance:", error);
    }
  }

  /// This function is used to read the amount of collateral deposited from contract
  async function fetchUserCollateralDeposited(address: `0x${string}`) {
    const result = await readContract(wagmiConfig, {
      abi: BorrowXABI,
      address: "0x7ACC45Ed7b25AED601Bf2b0880b865E7B8BdF7D2",
      functionName: "getUserCollateralDeposited",
      args: [address],
    });
    console.log(result);
    setCollateral({
      formatted: formatUnits(result as bigint, 18), // Convert `bigint` to string with 4 decimals
      symbol: "ETH",
    });
  }

  /// This function is used to read the amount of xUSDC borrowed by the user
  async function fetchUserBorrowAmount(address: `0x${string}`) {
    const result: bigint = (await readContract(wagmiConfig, {
      abi: BorrowXABI,
      address: "0x7ACC45Ed7b25AED601Bf2b0880b865E7B8BdF7D2",
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
      address: "0x7ACC45Ed7b25AED601Bf2b0880b865E7B8BdF7D2",
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
      address: "0x7ACC45Ed7b25AED601Bf2b0880b865E7B8BdF7D2",
      functionName: "getWithdrawAmountAllowed",
      args: [address],
    })) as bigint;
    setWithdrawAllowance({
      formatted: (Number(result) / 10 ** 18).toFixed(4), // Convert `bigint` to string with 4 decimals
      symbol: "ETH",
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
    ]);
    setIsLoading(false);
  };

  //////////////////////////////////////////////////////////////////////////////////////
  ///////////////////////Write to contract//////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////////////

  // Allow user to deposit collateral
  async function handleDepositCollateral(data: any) {
    try {
      const { amountDeposit } = data;

      setIsLoading(true);
      const txHash = await writeContract(wagmiConfig, {
        abi: BorrowXABI,
        address: "0x7ACC45Ed7b25AED601Bf2b0880b865E7B8BdF7D2",
        functionName: "depositCollateral",
        value: parseUnits(amountDeposit.toString(), 18),
      });
      await waitForTransactionReceipt(wagmiConfig, { hash: txHash });
      fetchUserData();

      setIsLoading(false);
    } catch (error) {
      console.log(error);
      setIsLoading(false);
    }
  }

  // Allow user to withdraw collateral
  // async function handleCollateralWithdrawal(amount: number) {
  //   try {
  //     setIsLoading(true);
  //     const txHash = await writeContract(wagmiConfig, {
  //       abi: BorrowXABI,
  //       address: "0x7ACC45Ed7b25AED601Bf2b0880b865E7B8BdF7D2",
  //       functionName: "withdrawCollateral",
  //       args: [BigInt(amount * PRECISION)],
  //     });
  //     await waitForTransactionReceipt(wagmiConfig, { hash: txHash });
  //     fetchUserData();
  //     setInputWithdraw(0);
  //     setIsLoading(false);
  //   } catch (error) {
  //     console.log(error);
  //     setIsLoading(false);
  //   }
  // }

  // Allow user to borrow funds
  async function handleBorrow(amount: number) {
    try {
      setIsLoading(true);
      const txHash = await writeContract(wagmiConfig, {
        abi: BorrowXABI,
        address: "0x7ACC45Ed7b25AED601Bf2b0880b865E7B8BdF7D2",
        functionName: "mintxUSDC",
        args: [BigInt(amount * PRECISION)],
      });
      await waitForTransactionReceipt(wagmiConfig, { hash: txHash });
      fetchUserData();
      setInputBorrow(0);
      setIsLoading(false);
    } catch (error) {
      console.log(error);
      setIsLoading(false);
    }
  }

  async function handlePayDebt(amount: number) {
    try {
      setIsLoading(true);
      const txHashApprove = await writeContract(wagmiConfig, {
        abi: xusdcABI,
        address: "0xBEed2827e2cb03ea4B4d4DA8A1CF8638D9CeCA27",
        functionName: "approve",
        args: [
          "0x7ACC45Ed7b25AED601Bf2b0880b865E7B8BdF7D2",
          BigInt(amount * PRECISION),
        ],
      });
      await waitForTransactionReceipt(wagmiConfig, { hash: txHashApprove });
      const txHash = await writeContract(wagmiConfig, {
        abi: BorrowXABI,
        address: "0x7ACC45Ed7b25AED601Bf2b0880b865E7B8BdF7D2",
        functionName: "burnxUSDC",
        args: [BigInt(amount * PRECISION)],
      });
      await waitForTransactionReceipt(wagmiConfig, { hash: txHash });
      fetchUserData();
      setInputPayDebt(0);
      setIsLoading(false);
    } catch (error) {
      console.log(error);
      setIsLoading(false);
    }
  }

  async function handleClosePosition() {
    try {
      setIsLoading(true);
      const txHashApprove = await writeContract(wagmiConfig, {
        abi: xusdcABI,
        address: "0xBEed2827e2cb03ea4B4d4DA8A1CF8638D9CeCA27",
        functionName: "approve",
        args: [
          "0x7ACC45Ed7b25AED601Bf2b0880b865E7B8BdF7D2",
          BigInt(Number(xusdcBalance?.formatted) * PRECISION),
        ],
      });
      await waitForTransactionReceipt(wagmiConfig, { hash: txHashApprove });
      const txHash = await writeContract(wagmiConfig, {
        abi: BorrowXABI,
        address: "0x7ACC45Ed7b25AED601Bf2b0880b865E7B8BdF7D2",
        functionName: "closePosition",
      });
      await waitForTransactionReceipt(wagmiConfig, { hash: txHash });
      fetchUserData();
      setIsLoading(false);
    } catch (error) {
      console.log(error);
      setIsLoading(false);
    }
  }

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
              {
                <p className="text-[10px] text-gray-400">
                  {collateral?.formatted} {collateral?.symbol}
                </p>
              }
              {
                <p className="text-[10px] text-gray-400">
                  {xusdcBalance?.formatted} {xusdcBalance?.symbol}
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

              <form className="flex w-full max-w-sm items-center space-x-2">
                <Input
                  type="number"
                  disabled={isLoading}
                  value={inputPayDebt}
                  onChange={(e) => setInputPayDebt(parseFloat(e.target.value))}
                />
                <Button
                  className="hover:bg-green-700"
                  disabled={isLoading}
                  type="submit"
                >
                  Pay debt
                </Button>
                <Button
                  className="hover:bg-green-700"
                  disabled={isLoading}
                  onClick={() => setInputPayDebt(Number(borrowed?.formatted))}
                >
                  Max
                </Button>
              </form>
              <div className="mt-1 flex w-full max-w-sm items-center space-x-2">
                <p>
                  Close position if you wish to pay the entire debt amount and
                  withdraw all collateral.
                </p>
                <Button
                  className="hover:bg-red-600"
                  disabled={isLoading}
                  onClick={() => handleClosePosition()}
                >
                  Close Position
                </Button>
              </div>
            </CardContent>
          </Card>

          <Card className="w-[400px] bg-gray-800 text-white">
            <CardHeader>
              <CardTitle>Collateral management</CardTitle>
            </CardHeader>
            <CardContent>
              <form
                className=" flex w-full max-w-sm items-center space-x-2"
                onSubmit={handleSubmitDeposit(handleDepositCollateral)}
              >
                <Input
                  disabled={isLoading}
                  type="number"
                  step="0.000001"
                  /*  min="0" */
                  placeholder="amount to deposit"
                  {...registerDeposit("amountDeposit", {
                    valueAsNumber: true,
                  })}
                  /*  value={inputCollateral}
                  onChange={(e) =>
                    setInputCollateral(parseFloat(e.target.value))
                  } */
                />

                <Button
                  type="submit"
                  disabled={isLoading}
                  className="hover:bg-green-700"
                >
                  Deposit
                </Button>
              </form>

              {errorsDeposit.amountDeposit && (
                <span className="text-red-500 text-xs mt-1">
                  {errorsDeposit.amountDeposit.message}
                </span>
              )}

              <WithdrawForm
                setIsLoading={setIsLoading}
                isLoading={isLoading}
                onfetchUserData={fetchUserData}
                withdrawAllowance={withdrawAllowance}
              />
              {/* <form
                className=" mt-1 flex w-full max-w-sm items-center space-x-2"
                onSubmit={handleSubmitWithdraw(() =>
                  handleCollateralWithdrawal(inputWithdraw)
                )}
              >
                <Input
                  disabled={isLoading}
                  type="number"
                  step="0.01"
                  min="0"
                  placeholder="amount to deposit"
                  {...registerWithdraw("amountWithdraw", {
                    valueAsNumber: true,
                  })}
                  value={inputWithdraw}
                  onChange={(e) =>
                    setInputWithdraw(parseFloat(e.target.value) || 0)
                  }
                />
                <Button
                  type="submit"
                  disabled={isLoading}
                  className="hover:bg-green-700"
                >
                  Withdraw
                </Button>
                <Button
                  disabled={isLoading}
                  onClick={() =>
                    setInputWithdraw(Number(withdrawAllowance?.formatted))
                  }
                  className="hover:bg-green-700"
                >
                  Max
                </Button>
              </form>
              {errorsWithdraw.amountWithdraw && (
                <span className="text-red-500 text-xs mt-1">
                  {errorsWithdraw.amountWithdraw.message}
                </span>
              )}
              <p className=" mt-1 text-[10px] text-gray-400">
                You can withdraw {withdrawAllowance?.formatted}{" "}
                {withdrawAllowance?.symbol}.
              </p> */}
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
                <Input
                  type="number"
                  value={inputBorrow}
                  onChange={(e) =>
                    setInputBorrow(parseFloat(e.target.value) || 0)
                  }
                  disabled={isLoading}
                />
                <Button
                  className="hover:bg-green-700"
                  disabled={isLoading}
                  onClick={() => handleBorrow(inputBorrow)}
                >
                  Borrow
                </Button>
                <Button
                  className="hover:bg-green-700"
                  disabled={isLoading}
                  onClick={() =>
                    setInputBorrow(Number(borrowAllowance?.formatted))
                  }
                >
                  Max
                </Button>
              </p>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
