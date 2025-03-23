//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Base_Test} from "../../../Base.t.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Constants} from "../../../utils/Constants.sol";
import {Events} from "../../../utils/Events.sol";
import {xUSDC} from "../../../../src/xUSDC.sol";
import {BorrowX} from "../../../../src/BorrowX.sol";
import {MockV3Aggregator} from "../../../mock/MockV3Aggregator.sol";
import {MadBorrowX} from "../../../mock/MockBorrowXFailedTransfer.sol";

contract depositCollateralTest is Base_Test {
    uint256 depositAmount = 1 ether;
    MadBorrowX madBorrowX;

    function setUp() public virtual override {
        Base_Test.setUp();
    }

    //////////////////////////
    ///depositCollateral
    //////////////////////////

    function test_RevertWhen_DepositAmountIsZero() public {
        // Make bob the caller of the function
        vm.startPrank(users.bob);

        // Expect the next call to revert with the {BorrowX__NeedsMoreThanZero} error
        vm.expectRevert(BorrowX.BorrowX__NeedsMoreThanZero.selector);

        // Run the test
        borrowXContract.depositCollateral{value: 0}();

        vm.stopPrank();
    }

    function test_deposit_RevertWhen_TransferFails() public {
        madBorrowX = new MadBorrowX(address(MockV3AggregatorContract), address(xUSDCContract));

        // Make bob the caller of the function
        vm.startPrank(users.bob);

        // Expect the next call to revert with the {BorrowX__NeedsMoreThanZero} error
        vm.expectRevert(BorrowX.BorrowX__TransferFailed.selector);

        // Run the test
        madBorrowX.depositCollateral{value: depositAmount}();

        vm.stopPrank();
    }

    function test_WhenDepositAmountIsNotZero() public {
        // Make bob the caller of the function
        vm.startPrank(users.bob);

        // Store the balance of bob and the balance of the contract before the deposit
        uint256 contractBalanceBefore = address(borrowXContract).balance;
        uint256 bobBalanceBefore = users.bob.balance;

        //Expect the {CollateralDeposited} event to be emitted
        vm.expectEmit();
        emit Events.CollateralDeposited({user: users.bob, amount: depositAmount});

        // Run the test
        borrowXContract.depositCollateral{value: depositAmount}();

        // Store the balance of bob and the balance of the contract after the deposit
        uint256 contractBalanceAfter = address(borrowXContract).balance;
        uint256 bobBalanceAfter = users.bob.balance;

        // Get bob's balance of collateral deposited
        uint256 collateralDeposited = borrowXContract.getUserCollateralDeposited(users.bob);

        // Assert the balance of collateral for Bob
        assertEq(collateralDeposited, depositAmount);

        // Assert the ETH balance of Bob and the contract after the deposit
        assertEq(contractBalanceAfter, contractBalanceBefore + depositAmount);
        assertEq(bobBalanceAfter, bobBalanceBefore - depositAmount);
    }
}
