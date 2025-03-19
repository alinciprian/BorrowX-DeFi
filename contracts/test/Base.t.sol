//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

import {xUSDC} from "../src/xUSDC.sol";
import {BorrowX} from "../src/BorrowX.sol";
import {MockV3Aggregator} from "./mock/MockV3Aggregator.sol";

contract depositCollateralTest is Test {
    BorrowX public borrowXContract;
    xUSDC public xUSDCContract;
    MockV3Aggregator public MockV3AggregatorContract;
    address ethUsdPriceFeedAddress = 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1;

    uint256 ownerUSDCStartingBalance = 1000e18;
    uint256 startingAmount = 100 ether;
    uint256 depositAmount = 1 ether;

    uint8 public constant DECIMALS = 8;
    int256 public constant ETH_USD_PRICE = 2000e8;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public {
        //deploy contracts
        MockV3AggregatorContract = new MockV3Aggregator(DECIMALS, ETH_USD_PRICE);
        xUSDCContract = new xUSDC();
        borrowXContract = new BorrowX(address(MockV3AggregatorContract), address(xUSDCContract));
        xUSDCContract.mint(bob, ownerUSDCStartingBalance);
        xUSDCContract.transferOwnership(address(borrowXContract));
        vm.deal(bob, 100 ether);
    }
}
