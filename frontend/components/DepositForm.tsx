import { Input } from "./ui/input";
import { Button } from "./ui/button";
import { BorrowXABI } from "@/config/BorrowXABI";
import { writeContract, waitForTransactionReceipt } from "@wagmi/core";
import { wagmiConfig } from "./Providers";
import { z } from "zod";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { parseUnits } from "viem";
import { BorrowXAddress } from "@/lib/constants";

export default function DepositForm({
  isLoading,
  setIsLoading,
  onfetchUserData,
}: {
  isLoading: boolean;
  setIsLoading: React.Dispatch<React.SetStateAction<boolean>>;
  onfetchUserData: () => void;
}) {
  const DepositSchema = z.object({
    amountDeposit: z
      .number({ message: "Amount to deposit must be a number" })
      .min(0, "Deposit amount must be greater than 0")
      .positive("Input must be greater than 0"),
  });
  type DepositSchemaType = z.infer<typeof DepositSchema>;

  const {
    register: registerDeposit,
    handleSubmit: handleSubmitDeposit,
    formState: { errors: errorsDeposit },
    setValue,
  } = useForm<DepositSchemaType>({ resolver: zodResolver(DepositSchema) });

  // Allow user to deposit collateral
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  async function handleDepositCollateral(data: any) {
    try {
      const { amountDeposit } = data;

      setIsLoading(true);
      const txHash = await writeContract(wagmiConfig, {
        abi: BorrowXABI,
        address: BorrowXAddress,
        functionName: "depositCollateral",
        value: parseUnits(amountDeposit.toString(), 18),
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
        Start by depositing some collateral.
      </p>
      <form
        className=" flex w-full max-w-sm items-center space-x-2 mb-4"
        onSubmit={handleSubmitDeposit(handleDepositCollateral)}
      >
        <div className=" w-full">
          <Input
            className="pr-14 w-[220px]"
            disabled={isLoading}
            type="number"
            step="0.01"
            placeholder="amount to deposit"
            {...registerDeposit("amountDeposit", {
              valueAsNumber: true,
            })}
          />
        </div>

        <Button
          type="submit"
          disabled={isLoading}
          className="bg-green-600 hover:bg-green-700"
        >
          Deposit
        </Button>
      </form>

      {errorsDeposit.amountDeposit && (
        <span className="text-red-500 text-xs mt-1">
          {errorsDeposit.amountDeposit.message}
        </span>
      )}
    </>
  );
}
