import { Button } from "./ui/button";
import { useState } from "react";
import { z } from "zod";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { BorrowXABI } from "@/config/BorrowXABI";
import { writeContract, waitForTransactionReceipt } from "@wagmi/core";
import { wagmiConfig } from "./Providers";
import { Input } from "./ui/input";
import { Badge } from "./ui/badge";
import { formatUnits, parseUnits } from "viem";

type BalanceType = {
  formatted: string;
  symbol: string;
};

const WithdrawSchema = z.object({
  amount: z
    .number({ message: "Amount to withdraw must be a number" })
    .min(0, "Withdraw amount must be greater than 0!")
    .positive("Input must be greater than 0"),
});
type WithdrawSchemaType = z.infer<typeof WithdrawSchema>;

export default function WithdrawForm({
  isLoading,
  setIsLoading,
  withdrawAllowance,
  onfetchUserData,
}: {
  isLoading: boolean;
  setIsLoading: React.Dispatch<React.SetStateAction<boolean>>;
  withdrawAllowance: BalanceType | null;
  onfetchUserData: () => void;
}) {
  const {
    register: registerWithdraw,
    handleSubmit: handleSubmitWithdraw,
    formState: { errors: errorsWithdraw },
    setValue,
  } = useForm<WithdrawSchemaType>({ resolver: zodResolver(WithdrawSchema) });

  // Allow user to withdraw collateral
  async function handleCollateralWithdrawal(data: any) {
    const { amount } = data;
    try {
      setIsLoading(true);
      const txHash = await writeContract(wagmiConfig, {
        abi: BorrowXABI,
        address: "0x7ACC45Ed7b25AED601Bf2b0880b865E7B8BdF7D2",
        functionName: "withdrawCollateral",
        args: [parseUnits(amount.toString(), 18)],
      });
      await waitForTransactionReceipt(wagmiConfig, { hash: txHash });
      onfetchUserData();

      setIsLoading(false);
    } catch (error) {
      console.log(error);
      setIsLoading(false);
    }
  }

  return (
    <>
      <form
        className=" mt-1 flex w-full max-w-sm items-center space-x-2"
        onSubmit={handleSubmitWithdraw(handleCollateralWithdrawal)}
      >
        <Input
          disabled={isLoading}
          type="number"
          step="0.000001"
          {...registerWithdraw("amount", {
            valueAsNumber: true,
          })}
        />
        <Button
          type="submit"
          disabled={isLoading}
          className="hover:bg-green-700"
        >
          Withdraw
        </Button>
      </form>
      <Badge
        /*  disabled={isLoading} */
        onClick={() => setValue("amount", Number(withdrawAllowance?.formatted))}
        className="hover:bg-green-700"
      >
        Max
      </Badge>
      {errorsWithdraw.amount && (
        <span className="text-red-500 text-xs mt-1">
          {errorsWithdraw.amount.message}
        </span>
      )}
      <p className=" mt-1 text-[10px] text-gray-400">
        You can withdraw {withdrawAllowance?.formatted}{" "}
        {withdrawAllowance?.symbol}.
      </p>
    </>
  );
}
