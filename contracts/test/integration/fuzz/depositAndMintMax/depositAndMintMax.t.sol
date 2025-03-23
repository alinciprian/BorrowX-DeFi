//SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Base_Test} from "../../../Base.t.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {Constants} from "../../../utils/Constants.sol";
import {Events} from "../../../utils/Events.sol";
import {xUSDC} from "../../../../src/xUSDC.sol";
import {BorrowX} from "../../../../src/BorrowX.sol";
import {MockV3Aggregator} from "../../../mock/MockV3Aggregator.sol";

contract depositAndMintMaxTestFuzz is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
    }

    //////////////////////////
    ///depositAndMintMax
    //////////////////////////

    /// @dev the function uses two functions which are tested separately : depositCollateral and mintxUSDC
    function testFuzz_depositAndMintMax(uint256 depositAmount) public {
        // We assume the input is valid
        vm.assume(depositAmount > 0);
        // We assume the deposit amount is less than 100_000 ETH to prevent the oracle from overflowing
        vm.assume(depositAmount < 100_000e18);

        // We deal eve sufficient funds
        vm.deal(users.eve, depositAmount);

        // Make eve the caller of the function
        vm.startPrank(users.eve);

        // Run the test
        borrowXContract.depositAndMintMax{value: depositAmount}();

        // We store the xUSDC balance of Eve
        uint256 eveBalance = xUSDCContract.balanceOf(users.eve);

        uint256 ethPrice = uint256(Constants.ETH_USD_PRICE);
        uint256 loan_to_value = Constants.LOAN_TO_VALUE;
        uint256 loan_precision = Constants.LOAN_PRECISION;

        // We compute the amount of xUSDC that eve should be allowed to mint
        uint256 eveShouldHave = ((depositAmount * ethPrice * loan_to_value) / loan_precision) / 1e8;

        // We assert that eve's balance is succesfully satisfying the conditions required by the protocol
        assertEq(eveBalance, eveShouldHave);
    }
}
