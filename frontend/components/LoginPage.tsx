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
    <div className="flex items-center justify-center h-screen">
      <Card className="w-[350px]">
        <CardHeader className="text-center">
          <CardTitle>STK staking app</CardTitle>
          <CardDescription>Please connect your wallet</CardDescription>
        </CardHeader>
        <CardFooter className="flex justify-center">
          <Button onClick={connectWallet}>Connect</Button>
        </CardFooter>
      </Card>
    </div>
  );
}
