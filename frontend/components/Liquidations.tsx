import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { useEffect, useState } from "react";
import { useAccount } from "wagmi";
import { shortenAddress } from "@/lib/utils";
import { formatUnits } from "viem";
import { Button } from "./ui/button";
import { BorrowXABI } from "@/config/BorrowXABI";
import { BorrowXAddress } from "@/lib/constants";
import {
  readContract,
  writeContract,
  waitForTransactionReceipt,
} from "@wagmi/core";
import { wagmiConfig } from "./Providers";

export default function Liquidations() {
  const [liquidationMap, setLiquidationMap] = useState<boolean[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  type Position = {
    account: string;
    borrowed: string;
    collateral: string;
    id: string;
    timestamp: string;
    txHash: string;
  };
  const { isConnected } = useAccount();
  const [positions, setPositions] = useState<Position[]>([]);

  const fetchPositions = async () => {
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
    setPositions(position);
  };

  /// This function is used to check wether a user is eligible for liquidation
  async function handleLiquidation(account: string, index: number) {
    try {
      const result: boolean = (await readContract(wagmiConfig, {
        abi: BorrowXABI,
        address: BorrowXAddress,
        functionName: "getLiquidationStatus",
        args: [account],
      })) as boolean;
      console.log(result);
      setLiquidationMap((prev) => {
        const updated = [...prev];
        updated[index] = result;
        return updated;
      });

      if (result) {
        try {
          setIsLoading(true);
          const txHash = await writeContract(wagmiConfig, {
            abi: BorrowXABI,
            address: BorrowXAddress,
            functionName: "mintxUSDC",
            args: [account],
          });
          await waitForTransactionReceipt(wagmiConfig, { hash: txHash });
          setIsLoading(false);
        } catch (error) {
          console.log(error);
          setIsLoading(false);
        }
      }
    } catch (error) {
      console.log(error);
    }
  }

  useEffect(() => {
    if (isConnected) {
      fetchPositions();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isConnected]);

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-black text-white p-4">
      {/* Uncomment if you want to show net worth */}
      {/* <div className="absolute top-4 left-4 text-[10px] font-semibold">
        <p className="text-gray-400">Net worth:</p>
        <div className="flex items-center text-white">
          <p className="text-gray-400">$</p>
          <p>{netWorth?.formatted}</p>
        </div>
      </div> */}

      <Card className="w-full max-w-md bg-gray-800 text-white shadow-lg rounded-2xl">
        <CardHeader>
          <CardTitle className="text-xl">Liquidations</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {positions.length === 0 ? (
            <p className="text-gray-400 text-center">
              No active liquidation positions.
            </p>
          ) : (
            positions.map((position, index) => (
              <div
                key={index}
                className="border border-gray-700 rounded-xl p-4 bg-gray-900 hover:bg-gray-800 transition-all"
              >
                <div className="mb-2">
                  <p className="text-sm text-gray-400">Account</p>
                  <p className="font-mono">
                    {shortenAddress(position.account)}
                  </p>
                </div>

                <div className="mb-2">
                  <p className="text-sm text-gray-400">Borrowed</p>
                  <p className="font-semibold">
                    {formatUnits(BigInt(position.borrowed), 18)} xUSDC
                  </p>
                </div>

                {/* Add more info if you want, like collateral, health factor, etc. */}

                <Button
                  disabled={isLoading}
                  variant="outline"
                  className="mt-2 w-full text-white border-white bg-green-600 hover:bg-green-700"
                  onClick={() => handleLiquidation(position.account, index)}
                >
                  {liquidationMap[index] ? "Liquidate" : "Check"}
                </Button>
              </div>
            ))
          )}
        </CardContent>
      </Card>
    </div>
  );
}
