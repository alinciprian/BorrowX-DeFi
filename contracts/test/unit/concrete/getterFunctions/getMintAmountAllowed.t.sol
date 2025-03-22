//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Base_Test} from "../../../Base.t.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Constants} from "../../../utils/Constants.sol";
import {xUSDC} from "../../../../src/xUSDC.sol";
import {BorrowX} from "../../../../src/BorrowX.sol";
import {MockV3Aggregator} from "../../../mock/MockV3Aggregator.sol";

contract depositCollateralTest is Base_Test {
    uint256 depositAmount = 1 ether;
    uint256 xUSDCMintAmount = 900e18;

    function setUp() public virtual override {
        Base_Test.setUp();

        // Make bob deposit 1 ether
        vm.startPrank(users.bob);
        borrowXContract.depositCollateral{value: depositAmount}();
    }

    function test_getMintAmountAllowed() public view {
        // Get the maximum amount allowed to mint
        uint256 amountMintAllowed = borrowXContract.getMintAmountAllowed(users.bob);
        // The amount to mint should be half of the collateral deposited -> 1_000 xUSDC
        // We assert the amount to mint
        assertEq(amountMintAllowed, 1000e18);
    }
}
