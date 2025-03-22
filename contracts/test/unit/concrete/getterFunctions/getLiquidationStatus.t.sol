//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Base_Test} from "../../../Base.t.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Constants} from "../../../utils/Constants.sol";
import {xUSDC} from "../../../../src/xUSDC.sol";
import {BorrowX} from "../../../../src/BorrowX.sol";
import {MockV3Aggregator} from "../../../mock/MockV3Aggregator.sol";
import {console} from "forge-std/Test.sol";

contract getLiquidationStatusTest is Base_Test {
    uint256 depositAmount = 1 ether;
    uint256 xUSDCMintAmount = 1000e18;
    int256 ethUsdUpdatedPrice = 1250e8;

    function setUp() public virtual override {
        Base_Test.setUp();

        // Make bob the caller
        vm.startPrank(users.bob);
        // Bob deposits and mints the maximum amount
        borrowXContract.depositAndMintMax{value: depositAmount}();
    }

    function test_LiquidationStatusIsFalse() public view {
        // Get bob's liquidation status
        bool liquidationStatus = borrowXContract.getLiquidationStatus(users.bob);
        // We assert that bob's liquidation status is false
        assertEq(liquidationStatus, false);
    }

    function test_LiquidationStatusIsTrue() public {
        // We lower the price of eth, making bob eligible for liquidation
        MockV3AggregatorContract.updateAnswer(ethUsdUpdatedPrice);
        // Get bob's liquidation status
        bool liquidationStatus = borrowXContract.getLiquidationStatus(users.bob);
        // We assert that bob's liquidation status is true
        assertEq(liquidationStatus, true);
    }
}
