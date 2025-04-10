import { useAccount, useDisconnect } from "wagmi";

export default function Navbar({ isLoading }: { isLoading: boolean }) {
  const { disconnect } = useDisconnect();
  const { address } = useAccount();

  function shortenAddress(address: `0x${string}`) {
    return `${address.slice(0, 4)}...${address.slice(-4)}`;
  }

  return (
    <nav className="bg-gray-800 text-white p-4 flex justify-between items-center">
      <div className="flex items-center space-x-6">
        {/* Logo */}

        <a href="#" className="hover:text-gray-300">
          Dashboard
        </a>
        <a href="#" className="hover:text-gray-300">
          Liquidations
        </a>
        <a href="#" className="hover:text-gray-300">
          Staking
        </a>
      </div>

      {/* Right Section: Wallet Address + Disconnect Button */}
      <div className="flex items-center space-x-4">
        <span className="text-gray-400">{shortenAddress(address!)}</span>
        <button
          className={
            isLoading
              ? "bg-gray-400  text-white px-4 py-2 rounded-lg"
              : "bg-black hover:bg-red-600 text-white px-4 py-2 rounded-lg"
          }
          onClick={() => disconnect()}
          disabled={isLoading}
        >
          Disconnect
        </button>
      </div>
    </nav>
  );
}
