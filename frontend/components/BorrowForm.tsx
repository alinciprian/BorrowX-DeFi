import { Input } from "./ui/input";
import { BalanceType } from "@/lib/utils";
import { Button } from "./ui/button";
import { BorrowXABI } from "@/config/BorrowXABI";
import { BorrowXAddress } from "@/lib/constants";
import { writeContract, waitForTransactionReceipt } from "@wagmi/core";
import { wagmiConfig } from "./Providers";
import { parseUnits } from "viem";
import { z } from "zod";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { Badge } from "./ui/badge";

export default function BorrowForm({
  isLoading,
  setIsLoading,
  onfetchUserData,
  borrowAllowance,
}: {
  isLoading: boolean;
  setIsLoading: React.Dispatch<React.SetStateAction<boolean>>;
  onfetchUserData: () => void;
  borrowAllowance: BalanceType | null;
}) {
  const BorrowSchema = z.object({
    amountDeposit: z
      .number({ message: "Amount to borrow must be a number" })
      .min(0, "Borrow amount must be greater than 0")
      .positive("Input must be greater than 0"),
  });
  type BorrowSchemaType = z.infer<typeof BorrowSchema>;
  const {
    register,
    handleSubmit,
    formState: { errors },
    setValue,
  } = useForm<BorrowSchemaType>({ resolver: zodResolver(BorrowSchema) });

  // Allow user to borrow funds
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  async function handleBorrow(data: any) {
    const { amountDeposit } = data;
    try {
      setIsLoading(true);
      const txHash = await writeContract(wagmiConfig, {
        abi: BorrowXABI,
        address: BorrowXAddress,
        functionName: "mintxUSDC",
        args: [parseUnits(amountDeposit.toString(), 18)],
      });
      await waitForTransactionReceipt(wagmiConfig, { hash: txHash });
      onfetchUserData();
      setValue("amountDeposit", 0);
      setIsLoading(false);
    } catch (error) {
      console.log(error);
      setIsLoading(false);
    }
  }

  return (
    <>
      <p className=" mb-1 text-[10px] text-gray-400">
        You can currently borrow {borrowAllowance?.formatted}{" "}
        {borrowAllowance?.symbol}.
      </p>
      <form
        className="flex w-full max-w-sm items-center space-x-2"
        onSubmit={handleSubmit(handleBorrow)}
      >
        <div className="relative w-full">
          <Input
            className="pr-14"
            disabled={isLoading}
            type="number"
            step="0.0000001"
            placeholder="amount to borrow"
            {...register("amountDeposit", {
              valueAsNumber: true,
            })}
          />
          <Badge
            className="absolute right-2 top-1/2 -translate-y-1/2 bg-black text-white px-2 py-1 text-xs cursor-pointer hover:bg-green-700"
            onClick={() =>
              setValue("amountDeposit", Number(borrowAllowance?.formatted))
            }
          >
            Max
          </Badge>
        </div>
        <Button
          type="submit"
          className="hover:bg-green-700"
          disabled={isLoading}
        >
          Borrow
        </Button>
      </form>

      {errors.amountDeposit && (
        <span className="text-red-500 text-xs mt-1">
          {errors.amountDeposit.message}
        </span>
      )}
    </>
  );
}
