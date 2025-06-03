# 📜 BorrowX Protocol

A decentralized borrowing protocol on Ethereum that allows users to deposit ETH as collateral and mint **xUSDC**, a USD-pegged stablecoin backed by ETH. BorrowX ensures over-collateralization and offers incentives for liquidators to maintain system solvency.

---

## 📖 Overview

BorrowX enables users to:

- **Deposit ETH** as collateral.
- **Mint xUSDC** against their ETH up to a **50% Loan-To-Value (LTV)** ratio.
- **Withdraw ETH** when their borrowing position allows.
- **Burn xUSDC** to repay debt and reduce liquidation risk.
- **Close positions** by repaying all debt and redeeming all collateral.
- **Liquidate undercollateralized positions**, earning a **10% bonus** on collateral value.

---

## 📊 Loan Parameters

| Parameter                 | Value | Description                                                              |
| :------------------------ | :---- | :----------------------------------------------------------------------- |
| **Loan-To-Value (LTV)**   | 50%   | Users can borrow up to 50% of the USD value of their collateral          |
| **Liquidation Threshold** | 80%   | Position is eligible for liquidation at this ratio                       |
| **Liquidation Bonus**     | 10%   | Bonus received by liquidators when closing undercollateralized positions |
| **Collateral Asset**      | ETH   | Native network token                                                     |
| **Borrowed Asset**        | xUSDC | USD-pegged stablecoin issued by BorrowX                                  |

---

## 📦 Contracts

- **BorrowX.sol** — Main protocol contract handling deposits, borrowing, repayment, liquidation.
- **xUSDC.sol** — ERC20-compliant stablecoin contract.
- **OracleLib.sol** — Secure price oracle wrapper library.

---

## 🔐 Security Features

- **CEI Pattern**: Checks-Effects-Interactions pattern to prevent reentrancy.
- **ReentrancyGuard**: OpenZeppelin implementation for additional protection.
- **Oracle Freshness Check**: Uses `staleCheckLatestRoundData()` for reliable price data.
- **Custom Errors**: Gas-efficient error handling for invalid actions.

---
