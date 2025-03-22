//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Base_Test} from "../../../Base.t.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Constants} from "../../../utils/Constants.sol";
import {xUSDC} from "../../../../src/xUSDC.sol";
import {BorrowX} from "../../../../src/BorrowX.sol";
import {MockV3Aggregator} from "../../../mock/MockV3Aggregator.sol";

contract getUserMintedTest is Base_Test {
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

    function test_getUserMinted() public view {
        // Get the maximum amount allowed to withdraw
        uint256 amountUserMinted = borrowXContract.getUserMintedXUSDC(users.bob);
        // We assert the amount bob minted is 500
        assertEq(amountUserMinted, 500);
    }
}
