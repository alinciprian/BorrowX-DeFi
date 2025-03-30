import {
  Card,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
  CardContent,
} from "@/components/ui/card";
import DepositForm from "./DepositForm";
import BorrowForm from "./BorrowForm";
import PayDebt from "./PayDebt";

export default function ManageBorrows() {
  return (
    <>
      <Card className="w-[400px] bg-gray-800 text-white">
        <CardHeader>
          <CardTitle> Manage borrows </CardTitle>
        </CardHeader>
        <CardContent className="text-[10px] text-gray-400">
          <DepositForm
            setIsLoading={setIsLoading}
            isLoading={isLoading}
            onfetchUserData={fetchUserData}
          />
          <BorrowForm
            setIsLoading={setIsLoading}
            isLoading={isLoading}
            onfetchUserData={fetchUserData}
            borrowAllowance={borrowAllowance}
          />
          <PayDebt
            setIsLoading={setIsLoading}
            isLoading={isLoading}
            onfetchUserData={fetchUserData}
            borrowed={borrowed}
          />
        </CardContent>
      </Card>
    </>
  );
}
