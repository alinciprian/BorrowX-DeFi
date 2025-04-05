import * as React from "react";
import { usePrivy } from "@privy-io/react-auth";

import { Button } from "@/components/ui/button";
import {
  Card,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

export default function LoginPage() {
  const { connectWallet } = usePrivy();
  return (
    <div className="flex flex-col items-center justify-center h-screen bg-black text-white relative">
      <Card className="w-[400px] bg-gray-800 text-white">
        <CardHeader className="text-center">
          <CardTitle>STK staking app</CardTitle>
          <CardDescription className="text-bold">
            Please connect your wallet
          </CardDescription>
        </CardHeader>
        <CardFooter className="flex justify-center">
          <Button
            onClick={connectWallet}
            className="bg-green-600 hover:bg-green-700"
          >
            Connect
          </Button>
        </CardFooter>
      </Card>
    </div>
  );
}
