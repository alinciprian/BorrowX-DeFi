import { BorrowX } from "generated";

BorrowX.CollateralRedeemed.handler(async ({ event, context }) => {
  const account = event.params.redeemFrom;
  const positionId = `${event.chainId}_${account}`;

  const position = await context.Position.get(positionId);

  context.Position.set({
    id: positionId,
    account: account,
    collateral: position!.collateral - event.params.amount,
    borrowed: BigInt(0),
    timestamp: BigInt(event.block.timestamp),
    txHash: event.transaction.hash,
  });
});
