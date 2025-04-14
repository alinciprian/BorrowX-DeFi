import { useAccount, useDisconnect } from "wagmi";
import Link from "next/link";

export default function Navbar() {
  const { disconnect } = useDisconnect();
  const { address } = useAccount();

  function shortenAddress(address: `0x${string}`) {
    return `${address.slice(0, 4)}...${address.slice(-4)}`;
  }

  return (
    <nav className="bg-gray-800 text-white p-4 flex justify-between items-center">
      <div className="flex items-center space-x-6">
        {/* Logo */}

        <Link href="/" className="hover:text-gray-300">
          Dashboard
        </Link>
        <Link href="/liquidations" className="hover:text-gray-300">
          Liquidations
        </Link>
        <a href="#" className="hover:text-gray-300">
          Staking
        </a>
      </div>

      {/* Right Section: Wallet Address + Disconnect Button */}
      <div className="flex items-center space-x-4">
        <span className="text-gray-400">{shortenAddress(address!)}</span>
        <button
          className="bg-black hover:bg-red-600 text-white px-4 py-2 rounded-lg"
          onClick={() => disconnect()}
        >
          Disconnect
        </button>
      </div>
    </nav>
  );
}
