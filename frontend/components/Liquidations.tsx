import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";

export default function Liquidations() {
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
        <CardContent></CardContent>
      </Card>
    </div>
  );
}
