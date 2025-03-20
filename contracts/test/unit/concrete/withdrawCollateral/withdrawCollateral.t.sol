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

contract depositCollateralTest is Base_Test {
    uint256 depositAmount = 1 ether;
    /// Ether value from Mock price feed is 2_000 . Given LTV is 50% , max xUSDC mint amount is 1_000
    uint256 MAXxUSDCMintAmount = 1000e18;
    MockFailedTransfer revertContract;

    function setUp() public virtual override {
        Base_Test.setUp();

        // revertContract is a contract that reverts when receiving ETH
        revertContract = new MockFailedTransfer();

        // Bob deposits some collateral into the protocol
        vm.prank(users.bob);
        borrowXContract.depositCollateral{value: depositAmount}();
    }

    function test_RevertWhen_withdrawAmountIsZero() public {
        // Make bob the caller
        vm.startPrank(users.bob);

        // We expect the next call to revert with the {BorrowX__NeedsMoreThanZero} error
        vm.expectRevert(Errors.BorrowX__NeedsMoreThanZero.selector);

        // We run the test
        borrowXContract.withdrawCollateral(0);
    }

    function test_RevertWhen_withdrawAmountExceedsBalance() public {
        // Make bob the caller
        vm.startPrank(users.bob);

        // We expect the next call to revert with the {BorrowX__InsuficientBalance} error
        vm.expectRevert(Errors.BorrowX__InsuficientBalance.selector);

        // We run the test
        borrowXContract.withdrawCollateral(depositAmount + 1);
    }

    function test_RevertWhen_withdrawAmountBreaksLTV() public {
        // Make bob the caller
        vm.startPrank(users.bob);

        // Bob deposited 1 ether worth 2_000 USD; According to the protocol he can mint max 1_000 xUSDC;
        borrowXContract.mintxUSDC(1000e18);

        // We expect the next call to revert with the {BorrowX__ExceedsLoanToValue} error
        vm.expectRevert(Errors.BorrowX__ExceedsLoanToValue.selector);

        // Since bob already minted the maximum amount, he can no longer withdraw without breaking LTV
        // Run test
        borrowXContract.withdrawCollateral(1);
    }

    function test_RevertWhen_TransferFails() public {
        // We deal funds to the contract
        vm.deal(address(revertContract), depositAmount);

        // Make the revertContract caller
        vm.startPrank(address(revertContract));

        // The contract deposits ETH into the protocol
        borrowXContract.depositCollateral{value: depositAmount}();

        // We expect the next call to revert with the {BorrowX__TransferFailed} error
        vm.expectRevert(Errors.BorrowX__TransferFailed.selector);

        // Run the test
        borrowXContract.withdrawCollateral(depositAmount);
    }

    function test_withdrawCollateral() public {
        // Make bob the caller
        vm.startPrank(users.bob);

        // we store bob collateral deposited before withdraw
        uint256 bobCollateralDepositedBefore = borrowXContract.getUserCollateralDeposited(users.bob);
        // we store bob ETH balance before
        uint256 bobETHBalanceBefore = users.bob.balance;

        // Expect the {CollateralRedeemed} event to be emitted
        vm.expectEmit();
        emit CollateralRedeemed(users.bob, users.bob, depositAmount);

        // We run the test
        borrowXContract.withdrawCollateral(depositAmount);

        // we store bob collateral deposited after withdraw
        uint256 bobCollateralDepositedAfter = borrowXContract.getUserCollateralDeposited(users.bob);
        // we store bob ETH balance after
        uint256 bobETHBalanceAfter = users.bob.balance;

        // We assert that the storage was updated accordingly
        assertEq(bobCollateralDepositedAfter, bobCollateralDepositedBefore - depositAmount);
        // We assert that funds were transfered
        assertEq(bobETHBalanceAfter, bobETHBalanceBefore + depositAmount);
    }
}
