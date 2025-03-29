import { Input } from "./ui/input";
import { BalanceType } from "@/lib/utils";
import { Button } from "./ui/button";
import { BorrowXABI } from "@/config/BorrowXABI";
import { BorrowXAddress } from "@/lib/constants";
import { xusdcABI } from "@/config/xusdcABI";
import { xUSDCAddress } from "@/lib/constants";
import { writeContract, waitForTransactionReceipt } from "@wagmi/core";
import { wagmiConfig } from "./Providers";
import { parseUnits } from "viem";
import { z } from "zod";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Badge } from "./ui/badge";

export default function PayDebt({
  isLoading,
  setIsLoading,
  onfetchUserData,
  borrowed,
}: {
  isLoading: boolean;
  setIsLoading: React.Dispatch<React.SetStateAction<boolean>>;
  onfetchUserData: () => void;
  borrowed: BalanceType | null;
}) {
  const PayDebtScehma = z.object({
    amountPay: z
      .number({ message: "Amount to borrow must be a number" })
      .min(0, "Borrow amount must be greater than 0")
      .positive("Input must be greater than 0"),
  });
  type PayDebtSchemaType = z.infer<typeof PayDebtScehma>;
  const {
    register,
    handleSubmit,
    formState: { errors },
    setValue,
  } = useForm<PayDebtSchemaType>({ resolver: zodResolver(PayDebtScehma) });

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  async function handlePayDebt(data: any) {
    const { amountPay } = data;
    try {
      setIsLoading(true);
      const txHashApprove = await writeContract(wagmiConfig, {
        abi: xusdcABI,
        address: xUSDCAddress,
        functionName: "approve",
        args: [BorrowXAddress, parseUnits(amountPay.toString(), 18)],
      });
      await waitForTransactionReceipt(wagmiConfig, { hash: txHashApprove });
      const txHash = await writeContract(wagmiConfig, {
        abi: BorrowXABI,
        address: BorrowXAddress,
        functionName: "burnxUSDC",
        args: [parseUnits(amountPay.toString(), 18)],
      });
      await waitForTransactionReceipt(wagmiConfig, { hash: txHash });
      onfetchUserData();
      setValue("amountPay", 0);
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
      <p className="mb-1">
        Your current debt: {borrowed?.formatted} {borrowed?.symbol}.
      </p>

      <form
        className="flex w-full max-w-sm items-center space-x-2"
        onSubmit={handleSubmit(handlePayDebt)}
      >
        <Input
          disabled={isLoading}
          type="number"
          step="0.000001"
          placeholder="amount debt to pay"
          {...register("amountPay", {
            valueAsNumber: true,
          })}
        />
        <Button
          className="hover:bg-green-700"
          disabled={isLoading}
          type="submit"
        >
          Pay debt
        </Button>
      </form>
      {errors.amountPay && (
        <span className="text-red-500 text-xs mt-1">
          {errors.amountPay.message}
        </span>
      )}
      <Badge
        className="hover:bg-green-700"
        onClick={() => setValue("amountPay", Number(borrowed?.formatted))}
      >
        Max
      </Badge>

      <div className="mt-1 flex w-full max-w-sm items-center space-x-2">
        <p>
          Close position if you wish to pay the entire debt amount and withdraw
          all collateral.
        </p>
        <Button
          className="hover:bg-red-600"
          disabled={isLoading}
          onClick={handleClosePosition}
        >
          Close Position
        </Button>
      </div>
    </>
  );
}
