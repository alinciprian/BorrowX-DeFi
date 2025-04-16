import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { useEffect, useState } from "react";
import { useAccount } from "wagmi";
import { shortenAddress } from "@/lib/utils";

export default function Liquidations() {
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

  useEffect(() => {
    if (isConnected) {
      fetchPositions();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isConnected]);

  return (
    <div className="flex flex-col items-center justify-center h-screen bg-black text-white relative">
      {/* <div className="absolute -top-15 left-2 text-[10px] font-semibold">
        <p className="text-gray-400">Net worth:</p>
        <div className="flex items-center text-white">
          <p className="text-gray-400">$ </p>
          <p> {netWorth?.formatted}</p>
        </div>
      </div> */}

      <Card className="w-[400px] bg-gray-800 text-white">
        <CardHeader>
          <CardTitle>Liquidations</CardTitle>
        </CardHeader>
        <CardContent>
          {positions.map((position) => (
            <p>{position.account}</p>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
