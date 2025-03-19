// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

library Constants {
    ///@dev Used for mockV3Aggregator deployment
    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;

    ///@dev 50% Loan-to-value, 80% liquidation threshold, 10% discount as liquidation incentive
    uint256 constant LOAN_TO_VALUE = 50;
    uint256 constant LOAN_LIQUIDATION_DISCOUNT = 10;
    uint256 constant LOAN_LIQUIDATION_THRESHOLD = 80;
    uint256 constant LOAN_PRECISION = 100;

    ///@dev 18 decimals for ETH and standard erc20 tokens
    uint256 constant PRECISION = 1e18;
}
