import { BalanceType } from "@/lib/utils";

export default function UserStats({
  collateral,
  xusdcBalance,
}: {
  collateral: BalanceType | null;
  xusdcBalance: BalanceType | null;
}) {
  return (
    <>
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
    </>
  );
}
