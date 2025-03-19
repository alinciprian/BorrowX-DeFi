// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library Errors {
    ///@notice Thrown when the transfer fails
    error BorrowX__TransferFailed();

    ///@notice Thrown when a function is called with input equal to 0
    error BorrowX__NeedsMoreThanZero();

    ///@notice Thrown when msg.value equal to 0 is sent to a payable function
    error BorrowX__MsgValueIsZero();

    ///@notice Thrown when minting fails
    error BorrowX__MintFailed();

    ///@notice Thrown when a user mints/withdraws more than the protocol allows
    error BorrowX__ExceedsLoanToValue();

    ///@notice Thrown when the amount to be withdrawn exceeds the user's balance
    error BorrowX__InsuficientBalance();

    ///@notice Thrown when trying to liquidate a user that is not eligible for liquidation
    error BorrowX__UserHasSufficientCollateral();

    ///@notice Thrown when debt was not paid before closing/liquidating a position
    error BorrowX__DebtWasNotPaid();
}
