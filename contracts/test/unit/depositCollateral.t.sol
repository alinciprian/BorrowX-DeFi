//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

import {xUSDC} from "../../src/xUSDC.sol";
import {BorrowX} from "../../src/BorrowX.sol";
import {MockV3Aggregator} from "../mock/MockV3Aggregator.sol";

contract depositCollateralTest is Test {
    BorrowX public borrowXContract;
    xUSDC public xUSDCContract;
    MockV3Aggregator public MockV3AggregatorContract;

    address ethUsdPriceFeedAddress = 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1;
    address public bob = makeAddr("bob");
    address public alice = makeAddr("alice");
    address public eve = makeAddr("eve");

    uint256 ownerUSDCStartingBalance = 1000e18;
    uint256 startingAmount = 100 ether;
    uint256 depositAmount = 5 ether;

    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;

    function setUp() public {
        //deploy contracts
        MockV3AggregatorContract = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        xUSDCContract = new xUSDC();
        borrowXContract = new BorrowX(address(MockV3AggregatorContract), address(xUSDCContract));
        xUSDCContract.mint(bob, ownerUSDCStartingBalance);
        xUSDCContract.transferOwnership(address(borrowXContract));
        vm.deal(bob, 100 ether);

        //vm.etch(ethUsdPriceFeedAddress, address(MockV3AggregatorContract).code);
    }

    //////////////////////////
    ///depositCollateral
    //////////////////////////

    function testItShouldRevertIfAmountIsZero() public {
        vm.startPrank(bob);

        vm.expectRevert(BorrowX.BorrowX__NeedsMoreThanZero.selector);
        borrowXContract.depositCollateral{value: 0}();

        vm.stopPrank();
    }

    function testItShouldUpdateStorage() public {
        vm.startPrank(bob);

        borrowXContract.depositCollateral{value: depositAmount}();
        uint256 collateralDeposited = borrowXContract.getUserCollateralDeposited(bob);
        assertEq(depositAmount, collateralDeposited);

        vm.stopPrank();
    }

    function testItShouldTransferFunds() public {
        vm.startPrank(bob);

        uint256 contractBalanceBefore = address(borrowXContract).balance;
        uint256 ownerBalanceBefore = address(bob).balance;

        borrowXContract.depositCollateral{value: depositAmount}();

        uint256 contractBalanceAfter = address(borrowXContract).balance;
        uint256 ownerBalanceAfter = address(bob).balance;

        assertEq(contractBalanceAfter, contractBalanceBefore + depositAmount);
        assertEq(ownerBalanceAfter, ownerBalanceBefore - depositAmount);

        vm.stopPrank();
    }

    function testItshouldEmitEvent() public {
        vm.startPrank(bob);
        vm.expectEmit();
        emit BorrowX.CollateralDeposited(bob, depositAmount);
        borrowXContract.depositCollateral{value: depositAmount}();
        vm.stopPrank();
    }

    //////////////////////////
    ///mintxUSDC
    //////////////////////////

    function testItShouldRevertIfMintAmountIsZero() public {
        vm.startPrank(bob);

        vm.expectRevert(BorrowX.BorrowX__NeedsMoreThanZero.selector);
        borrowXContract.mintxUSDC(0);

        vm.stopPrank();
    }

    function testItShouldRevertIfMintingExceedsLTV() public {
        vm.startPrank(bob);

        borrowXContract.mintxUSDC(10e18);
        //borrowXContract.depositCollateral{value: depositAmount}();

        vm.stopPrank();
    }
}
