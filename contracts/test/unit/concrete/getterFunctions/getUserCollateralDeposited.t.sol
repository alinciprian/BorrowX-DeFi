//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Base_Test} from "../../../Base.t.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Constants} from "../../../utils/Constants.sol";
import {xUSDC} from "../../../../src/xUSDC.sol";
import {BorrowX} from "../../../../src/BorrowX.sol";
import {MockV3Aggregator} from "../../../mock/MockV3Aggregator.sol";

contract getUserCollateralDepositTest is Base_Test {
    uint256 depositAmount = 1 ether;
    uint256 xUSDCMintAmount = 900e18;

    function setUp() public virtual override {
        Base_Test.setUp();

        // Make bob deposit 1 ether
        vm.startPrank(users.bob);
        borrowXContract.depositCollateral{value: depositAmount}();
        // Make bob mint 500xUSDC
        borrowXContract.mintxUSDC(500);
    }

    function test_getWithdrawAmountAllowed() public view {
        // Get the maximum amount allowed to withdraw
        uint256 amountToWithdrawAllowed = borrowXContract.getWithdrawAmountAllowed(users.bob);
        // Bob deposited 1 ether worth 2_000 and minted 500 xUSDC. He should be allowed to withdraw 0,5 ether
        // We assert the amount to to withdraw
        assertEq(amountToWithdrawAllowed, 5e17);
    }
}
