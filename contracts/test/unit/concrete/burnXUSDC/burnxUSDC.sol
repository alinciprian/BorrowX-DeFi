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
    /// Ether value from Mock price feed is 2_000 . Given LTV is 50% , max xUSDC mint amount is 1_000 xUSDC
    uint256 MAXxUSDCMintAmount = 1000e18;
    MockFailedTransfer revertContract;

    function setUp() public virtual override {
        Base_Test.setUp();

        // Bob deposits some collateral into the protocol
        vm.startPrank(users.bob);
        borrowXContract.depositCollateral{value: depositAmount}();

        // Bob  mints the max amount of xUSDC valaible
        borrowXContract.mintxUSDC(MAXxUSDCMintAmount);

        // We approve borrowXContract for xUSDC spending
        xUSDCContract.approve(address(borrowXContract), type(uint256).max);

        vm.stopPrank();
    }

    function test_revertWhen_burnAmountIsZero() public {
        // Make bob the caller
        vm.startPrank(users.bob);

        // Expect the next call to revert with {BorrowX__NeedsMoreThanZero}
        vm.expectRevert(Errors.BorrowX__NeedsMoreThanZero.selector);

        // Run the test
        borrowXContract.burnxUSDC(0);
    }

    function test_revertWhen_userHasInsufficientBalance() public {
        // Make bob the caller
        vm.startPrank(users.bob);

        // Expect the next call to revert with {BorrowX__InsuficientBalance}
        vm.expectRevert(Errors.BorrowX__InsuficientBalance.selector);

        // Run the test
        borrowXContract.burnxUSDC(MAXxUSDCMintAmount + 1);
    }

    function test_burnXUSDC() public {
        // Make bob the caller
        vm.startPrank(users.bob);

        // Get the  amount minted from storage - before burning
        uint256 bobAmountMintedBefore = borrowXContract.getUserMintedXUSDC(users.bob);

        // Get the xUSDC balance of Bob
        uint256 xUSDCBobBalanceBefore = xUSDCContract.balanceOf(users.bob);

        // We expect the {xUSDCBurnt} event to bve emitted
        vm.expectEmit();
        emit Events.xUSDCBurnt(users.bob, users.bob, MAXxUSDCMintAmount);

        // Run the tests
        borrowXContract.burnxUSDC(MAXxUSDCMintAmount);

        // Get the amount minted from storage - after burning
        uint256 bobAmountMintedAfter = borrowXContract.getUserMintedXUSDC(users.bob);

        // Get the xUSDC balance of borrowXContract after burning
        uint256 xUSDCContractBalanceAfter = xUSDCContract.balanceOf(address(borrowXContract));
        // Get the xUSDC balance of Bob
        uint256 xUSDCBobBalanceAfter = xUSDCContract.balanceOf(users.bob);

        // We assert that the storage was updated as expected
        assertEq(bobAmountMintedAfter, bobAmountMintedBefore - MAXxUSDCMintAmount);

        // We assert that the funds were transfered from bob
        assertEq(xUSDCBobBalanceAfter, xUSDCBobBalanceBefore - MAXxUSDCMintAmount);

        // We assert that the funds were burnt
        assertEq(xUSDCContractBalanceAfter, 0);
    }
}
