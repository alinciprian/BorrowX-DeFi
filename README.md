## How It Works

Users deposit ETH to open a collateralized position.

```solidity
borrowX.depositCollateral{value: 1 ether}();
```

Mint xUSDC Against Collateral
Users can mint up to 50% of the USD value of their deposited ETH.

```solidity
borrowX.mintxUSDC(500 * 1e18); // Mint up to allowed amount based on LTV
```

 Repay Debt by Burning xUSDC
Users can reduce their outstanding debt and avoid liquidation by burning xUSDC.

```solidity
borrowX.burnxUSDC(200 * 1e18);
```

 Withdraw ETH Collateral
If the borrowing position allows (based on LTV and debt), users can withdraw collateral.

```solidity
borrowX.withdrawCollateral(0.5 ether);
```

 Close Position (Repay All Debt and Withdraw All Collateral)
To completely close a position, users repay all outstanding xUSDC and redeem all remaining ETH.

```solidity
borrowX.closePosition();
```

 Liquidate Undercollateralized Positions
If a position’s LTV exceeds 80%, it can be liquidated by anyone for a 10% collateral bonus.

```solidity
borrowX.liquidate(targetUser);
```
