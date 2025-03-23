//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Base_Test} from "../../../Base.t.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Constants} from "../../../utils/Constants.sol";
import {xUSDC} from "../../../../src/xUSDC.sol";
import {BorrowX} from "../../../../src/BorrowX.sol";
import {MockV3Aggregator} from "../../../mock/MockV3Aggregator.sol";

contract mintxUSDCTestFuzz is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
    }

    //////////////////////////
    ///mintxUSDC
    //////////////////////////

    function testFuzz_MintXUSDC(uint256 depositAmount, uint256 xUSDCMintAmount) public {
        // We assume the input si valid
        vm.assume(xUSDCMintAmount > 0);
        vm.assume(depositAmount > 0);

        // We limit xUSDCMintAmount to a reasonably large amount to prevent the Mock oracle from overflowing
        vm.assume(xUSDCMintAmount < 1_000_000_000e18);

        (, int256 price,,,) = MockV3AggregatorContract.latestRoundData();
        vm.assume(xUSDCMintAmount * 1e9 < (depositAmount * uint256(price)) * 5);

        // Make bob caller of the function
        vm.startPrank(users.bob);

        // bob deposits 1 ether so he is able to mint max 1000 xUSDC
        borrowXContract.depositCollateral{value: depositAmount}();

        // Expect the {collateralDeposited} event to be emitted
        vm.expectEmit();
        emit BorrowX.xUSDCMinted(users.bob, xUSDCMintAmount);

        // Run the test
        borrowXContract.mintxUSDC(xUSDCMintAmount);

        // We store the amount of xUSDC bob minted according to the storage
        uint256 bobMinted = borrowXContract.getUserMintedXUSDC(users.bob);

        // We store bob's xUSDC balance from the xUSDC contract
        uint256 bobXUSDCBalance = xUSDCContract.balanceOf(users.bob);

        // Assert the storage is updated according to the amount minted
        assertEq(bobMinted, xUSDCMintAmount);

        // Assert xUSDC has been transfered to bob
        assertEq(bobXUSDCBalance, xUSDCMintAmount);
    }
}
