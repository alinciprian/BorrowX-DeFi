//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Base_Test} from "../../../Base.t.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Constants} from "../../../utils/Constants.sol";
import {Events} from "../../../utils/Events.sol";
import {xUSDC} from "../../../../src/xUSDC.sol";
import {BorrowX} from "../../../../src/BorrowX.sol";
import {MockV3Aggregator} from "../../../mock/MockV3Aggregator.sol";

contract closePositionTest is Base_Test {
    uint256 depositAmount = 1 ether;
    /// Ether value from Mock price feed is 2_000 . Given LTV is 50% , max xUSDC mint amount is 1_000 xUSDC
    uint256 MAXxUSDCMintAmount = 1000e18;

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

    /// @dev the function uses two functions which are tested separately : burnxUSDC and withdrawCollateral
    function test_closePosition() public {
        // Make Bob the caller
        vm.startPrank(users.bob);

        // Get bob's ether balance before closing position
        uint256 bobETHBalanceBefore = users.bob.balance;

        // Run the test
        borrowXContract.closePosition();

        // Get bob's ether balance after closing position
        uint256 bobETHBalanceAfter = users.bob.balance;
        // Get bob's xUSDC balance after closing position
        uint256 bobxUSDCBalance = xUSDCContract.balanceOf(users.bob);

        // Assert that ETH was transfered
        assertEq(bobETHBalanceAfter, bobETHBalanceBefore + depositAmount);
        // Assert that Bob's xUSDC balance is 0 because he burnt the entire amount
        assertEq(bobxUSDCBalance, 0);
    }
}
