/*
 * Please refer to https://docs.envio.dev for a thorough guide on all Envio indexer features
 */
import {
  BorrowX,
  BorrowX_CollateralDeposited,
  BorrowX_CollateralRedeemed,
  BorrowX_xUSDCBurnt,
  BorrowX_xUSDCMinted,
} from "generated";

BorrowX.CollateralDeposited.handler(async ({ event, context }) => {
  const entity: BorrowX_CollateralDeposited = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    user: event.params.user,
    amount: event.params.amount,
  };

  context.BorrowX_CollateralDeposited.set(entity);
});

BorrowX.CollateralRedeemed.handler(async ({ event, context }) => {
  const entity: BorrowX_CollateralRedeemed = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    redeemFrom: event.params.redeemFrom,
    redeemTo: event.params.redeemTo,
    amount: event.params.amount,
  };

  context.BorrowX_CollateralRedeemed.set(entity);
});

BorrowX.xUSDCBurnt.handler(async ({ event, context }) => {
  const entity: BorrowX_xUSDCBurnt = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    from: event.params.from,
    onBehalfOf: event.params.onBehalfOf,
    amount: event.params.amount,
  };

  context.BorrowX_xUSDCBurnt.set(entity);
});

BorrowX.xUSDCMinted.handler(async ({ event, context }) => {
  const entity: BorrowX_xUSDCMinted = {
    id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
    user: event.params.user,
    amount: event.params.amount,
  };

  context.BorrowX_xUSDCMinted.set(entity);
});
