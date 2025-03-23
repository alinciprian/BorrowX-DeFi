//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Base_Test} from "../../../Base.t.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Constants} from "../../../utils/Constants.sol";
import {xUSDC} from "../../../../src/xUSDC.sol";
import {BorrowX} from "../../../../src/BorrowX.sol";
import {MockV3Aggregator} from "../../../mock/MockV3Aggregator.sol";
import {Errors} from "../../../utils/Errors.sol";
import {Events} from "../../../utils/Events.sol";
import {MockFailedTransfer} from "../../../mock/MockFailedTransfer.sol";

contract withdrawCollateralTestFuzz is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
    }

    function testFuzz_withdrawCollateral(uint256 depositAmount, uint256 withdrawAmount) public {
        // Assume valid input
        vm.assume(depositAmount > 0);
        vm.assume(depositAmount < 100_000e18);

        // Assume user does not try to withdraw more than he deposits
        vm.assume(withdrawAmount < depositAmount);

        // Deal bob sufficient amount of funds
        vm.deal(users.bob, depositAmount);

        // Make bob the caller
        vm.startPrank(users.bob);

        // Bob deposits collateral
        borrowXContract.depositCollateral{value: depositAmount}();

        // We store bob collateral deposited before withdraw
        uint256 bobCollateralDepositedBefore = borrowXContract.getUserCollateralDeposited(users.bob);
        // We store bob ETH balance before
        uint256 bobETHBalanceBefore = users.bob.balance;

        // Expect the {CollateralRedeemed} event to be emitted
        vm.expectEmit();
        emit CollateralRedeemed(users.bob, users.bob, depositAmount);

        // We run the test
        borrowXContract.withdrawCollateral(depositAmount);

        // We store bob collateral deposited after withdraw
        uint256 bobCollateralDepositedAfter = borrowXContract.getUserCollateralDeposited(users.bob);
        // We store bob ETH balance after
        uint256 bobETHBalanceAfter = users.bob.balance;

        // We assert that the storage was updated accordingly
        assertEq(bobCollateralDepositedAfter, bobCollateralDepositedBefore - depositAmount);
        // We assert that funds were transfered
        assertEq(bobETHBalanceAfter, bobETHBalanceBefore + depositAmount);
    }
}
