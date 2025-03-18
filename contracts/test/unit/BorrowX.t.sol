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
    uint256 depositAmount = 1 ether;

    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;

    uint256 constant LOAN_TO_VALUE = 50;
    uint256 constant LOAN_LIQUIDATION_DISCOUNT = 10;
    uint256 constant LOAN_LIQUIDATION_THRESHOLD = 80;
    uint256 constant LOAN_PRECISION = 100;

    uint256 constant PRECISION = 1e18;
    uint256 constant ADDITIONAL_FEED_PRECISION = 1e10;

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

    function testItShouldRevertIfDepositAmountIsZero() public {
        vm.startPrank(bob);

        vm.expectRevert(BorrowX.BorrowX__NeedsMoreThanZero.selector);
        borrowXContract.depositCollateral{value: 0}();

        vm.stopPrank();
    }

    function testItShouldUpdateStorageAfterDeposit() public {
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

        vm.expectRevert(BorrowX.BorrowX__ExceedsLoanToValue.selector);
        borrowXContract.mintxUSDC(10e18);

        vm.stopPrank();
    }

    function testItShouldUpdateStorageAfterMinting() public {
        vm.deal(alice, 1 ether);
        vm.startPrank(alice);

        borrowXContract.depositCollateral{value: depositAmount}();
        borrowXContract.mintxUSDC(900e18);

        uint256 aliceMinted = borrowXContract.getUserMintedXUSDC(alice);

        assertEq(aliceMinted, 900e18);

        vm.stopPrank();
    }

    function testItShouldTransferFundsAfterMinting() public {
        vm.deal(alice, 1 ether);
        vm.startPrank(alice);

        borrowXContract.depositCollateral{value: depositAmount}();
        borrowXContract.mintxUSDC(900e18);

        uint256 aliceBalance = xUSDCContract.balanceOf(alice);
        assertEq(aliceBalance, 900e18);

        vm.stopPrank();
    }

    function testItShouldEmitEventAfterMinting() public {
        vm.deal(alice, 1 ether);
        vm.startPrank(alice);

        borrowXContract.depositCollateral{value: depositAmount}();

        vm.expectEmit();
        emit BorrowX.xUSDCMinted(alice, 900e18);
        borrowXContract.mintxUSDC(900e18);

        vm.stopPrank();
    }

    //////////////////////////
    ///depositAndMintMax
    //////////////////////////

    function testItShouldDepositAndMintMaxAmount() public {
        vm.deal(alice, 2 ether);
        vm.startPrank(alice);

        borrowXContract.depositAndMintMax{value: 2 * depositAmount}();

        uint256 aliceBalance = xUSDCContract.balanceOf(alice);
        console.log(
            "collateral price", ((depositAmount * uint256(ETH_USD_PRICE) * LOAN_TO_VALUE) / LOAN_PRECISION) / 1e8
        );
        uint256 aliceShouldHave = ((2 * depositAmount * uint256(ETH_USD_PRICE) * LOAN_TO_VALUE) / LOAN_PRECISION) / 1e8;

        assertEq(aliceBalance, aliceShouldHave);
    }
}
