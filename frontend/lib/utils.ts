import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export type BalanceType = {
  formatted: string;
  symbol: string;
};

export function shortenAddress(address: `0x${string}`) {
  return `${address.slice(0, 4)}...${address.slice(-4)}`;
}
