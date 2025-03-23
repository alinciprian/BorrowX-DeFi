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

contract burnxUSDCTestFuzz is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
    }

    function testFuzz_burnXUSDC(uint256 depositAmount, uint256 mintAmount, uint256 burnAmount) public {
        // We asume valid input
        vm.assume(mintAmount > 0);
        vm.assume(burnAmount > 0);
        vm.assume(depositAmount > 0);

        // We limit xUSDCMintAmount to a reasonably large amount to prevent the Mock oracle from overflowing
        vm.assume(depositAmount < 100_000e18);

        // We assume mint amount does not break LTV
        (, int256 price,,,) = MockV3AggregatorContract.latestRoundData();
        vm.assume(mintAmount < ((depositAmount * uint256(price)) * 5) / 1e9);

        // We assume user does not  burn more than he mints
        vm.assume(burnAmount < mintAmount);

        // We deal bob sufficient amount of funds
        vm.deal(users.bob, depositAmount);

        // Make bob the caller
        vm.startPrank(users.bob);

        // Bob deposits collateral
        borrowXContract.depositCollateral{value: depositAmount}();

        // Bob  mints the max amount of xUSDC valaible
        borrowXContract.mintxUSDC(mintAmount);

        // We approve borrowXContract for xUSDC spending
        xUSDCContract.approve(address(borrowXContract), type(uint256).max);

        // Get the  amount minted from storage before burning
        uint256 bobAmountMintedBefore = borrowXContract.getUserMintedXUSDC(users.bob);

        // Get the xUSDC balance of Bob
        uint256 xUSDCBobBalanceBefore = xUSDCContract.balanceOf(users.bob);

        // We expect the {xUSDCBurnt} event to bve emitted
        vm.expectEmit();
        emit Events.xUSDCBurnt(users.bob, users.bob, burnAmount);

        // Run the tests
        borrowXContract.burnxUSDC(burnAmount);

        // Get the amount minted from storage after burning
        uint256 bobAmountMintedAfter = borrowXContract.getUserMintedXUSDC(users.bob);

        // Get the xUSDC balance of borrowXContract after burning
        uint256 xUSDCContractBalanceAfter = xUSDCContract.balanceOf(address(borrowXContract));
        // Get the xUSDC balance of Bob
        uint256 xUSDCBobBalanceAfter = xUSDCContract.balanceOf(users.bob);

        // We assert that the storage was updated as expected
        assertEq(bobAmountMintedAfter, bobAmountMintedBefore - burnAmount);

        // We assert that the funds were transfered from bob
        assertEq(xUSDCBobBalanceAfter, xUSDCBobBalanceBefore - burnAmount);

        // We assert that the funds were burnt
        assertEq(xUSDCContractBalanceAfter, 0);
    }
}
