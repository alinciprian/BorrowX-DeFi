import { Input } from "./ui/input";
import { BalanceType } from "@/lib/utils";
import { Button } from "./ui/button";
import { BorrowXABI } from "@/config/BorrowXABI";
import { BorrowXAddress } from "@/lib/constants";
import { writeContract, waitForTransactionReceipt } from "@wagmi/core";
import { wagmiConfig } from "./Providers";
import { parseUnits } from "viem";

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
  // Allow user to borrow funds
  async function handleBorrow(amount: number) {
    try {
      setIsLoading(true);
      const txHash = await writeContract(wagmiConfig, {
        abi: BorrowXABI,
        address: BorrowXAddress,
        functionName: "mintxUSDC",
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
      <p className=" mb-1 text-[10px] text-gray-400">
        You can currently borrow {borrowAllowance?.formatted}{" "}
        {borrowAllowance?.symbol}.
      </p>
      <form className="flex w-full max-w-sm items-center space-x-2">
        <Input type="number" disabled={isLoading} />
        <Button className="hover:bg-green-700" disabled={isLoading}>
          Borrow
        </Button>
        <Button
          className="hover:bg-green-700"
          disabled={isLoading}
          onClick={() => setInputBorrow(Number(borrowAllowance?.formatted))}
        >
          Max
        </Button>
      </form>
    </>
  );
}
