//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

import {xUSDC} from "../../../src/xUSDC.sol";
import {BorrowX} from "../../../src/BorrowX.sol";

contract depositCollateralTest is Test {
    BorrowX public borrowXContract;
    xUSDC public xUSDCContract;

    address ethPriceFeedAddress = 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1;
    address public owner = makeAddr("owner");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    uint256 ownerUSDCStartingBalance = 1000e18;
    uint256 startingAmount = 100 ether;
    uint256 depositAmount = 5 ether;

    function setUp() public {
        //deploy contracts
        xUSDCContract = new xUSDC();
        borrowXContract = new BorrowX(ethPriceFeedAddress, address(xUSDCContract));
        xUSDCContract.mint(owner, ownerUSDCStartingBalance);
        vm.deal(owner, 100 ether);
    }

    /// When the amount sent is invalid

    function testItShouldRevertIfAmountIsZero() public {
        vm.startPrank(owner);

        vm.expectRevert(BorrowX.BorrowX__NeedsMoreThanZero.selector);
        borrowXContract.depositCollateral{value: 0}();

        vm.stopPrank();
        // uint256 collateralDeposited = borrowXContract.getUserCollateralDeposited(owner);
        //  assertEq(depositAmount, collateralDeposited);
    }
}
