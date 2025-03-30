import { Button } from "./ui/button";
import { z } from "zod";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { BorrowXABI } from "@/config/BorrowXABI";
import { writeContract, waitForTransactionReceipt } from "@wagmi/core";
import { wagmiConfig } from "./Providers";
import { Input } from "./ui/input";
import { Badge } from "./ui/badge";
import { parseUnits } from "viem";
import { BorrowXAddress } from "@/lib/constants";
import { BalanceType } from "@/lib/utils";
import { xusdcABI } from "@/config/xusdcABI";
import { xUSDCAddress } from "@/lib/constants";

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
  borrowed,
}: {
  isLoading: boolean;
  setIsLoading: React.Dispatch<React.SetStateAction<boolean>>;
  withdrawAllowance: BalanceType | null;
  onfetchUserData: () => void;
  borrowed: BalanceType | null;
}) {
  const {
    register: registerWithdraw,
    handleSubmit: handleSubmitWithdraw,
    formState: { errors: errorsWithdraw },
    setValue,
  } = useForm<WithdrawSchemaType>({ resolver: zodResolver(WithdrawSchema) });

  // Allow user to withdraw collateral
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  async function handleCollateralWithdrawal(data: any) {
    const { amount } = data;
    try {
      setIsLoading(true);
      const txHash = await writeContract(wagmiConfig, {
        abi: BorrowXABI,
        address: BorrowXAddress,
        functionName: "withdrawCollateral",
        args: [parseUnits(amount.toString(), 18)],
      });
      await waitForTransactionReceipt(wagmiConfig, { hash: txHash });
      onfetchUserData();
      setValue("amount", 0);
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
        address: xUSDCAddress,
        functionName: "approve",
        args: [BorrowXAddress, parseUnits(borrowed!.formatted, 18)],
      });
      await waitForTransactionReceipt(wagmiConfig, { hash: txHashApprove });
      const txHash = await writeContract(wagmiConfig, {
        abi: BorrowXABI,
        address: BorrowXAddress,
        functionName: "closePosition",
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
      {/* Withdrawable Balance Info */}
      <p className="mt-1 text-[10px] text-gray-400">
        You can withdraw {withdrawAllowance?.formatted}{" "}
        {withdrawAllowance?.symbol}.
      </p>

      {/* Withdraw Form - Compact & Aligned */}
      <form
        className="mt-2 flex w-full flex-col gap-2"
        onSubmit={handleSubmitWithdraw(handleCollateralWithdrawal)}
      >
        {/* Input + Max Button */}
        <div className="relative">
          <Input
            disabled={isLoading}
            type="number"
            placeholder="Amount to withdraw"
            step="0.01"
            {...registerWithdraw("amount", { valueAsNumber: true })}
            className="w-full pr-12 text-sm"
          />
          <Badge
            onClick={() =>
              setValue("amount", Number(withdrawAllowance?.formatted))
            }
            className="absolute right-2 top-1/2 -translate-y-1/2 bg-black text-white px-2 py-1 text-[10px] cursor-pointer hover:bg-green-700"
          >
            Max
          </Badge>
        </div>

        {/* Withdraw Button - Fixed Width */}
        <Button
          type="submit"
          disabled={isLoading}
          className="w-full bg-green-600 hover:bg-green-700 text-sm"
        >
          Withdraw
        </Button>

        {/* Error Message */}
        {errorsWithdraw.amount && (
          <span className="text-red-500 text-xs">
            {errorsWithdraw.amount.message}
          </span>
        )}
      </form>

      {/* Close Position Section - Aligned */}
      <div className="mt-3 flex w-full items-center justify-between gap-2 text-xs">
        <p className="text-gray-500">
          Close position to pay all debt and withdraw all collateral.
        </p>
        <Button
          className="bg-red-600 hover:bg-red-700 px-3 py-1 text-xs"
          disabled={isLoading}
          onClick={handleClosePosition}
        >
          Close position
        </Button>
      </div>
    </>
  );
}
