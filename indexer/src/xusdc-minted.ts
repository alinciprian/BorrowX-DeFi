import { BorrowX } from "generated";

BorrowX.XUSDCMinted.handler(async ({ event, context }) => {
  const account = event.params.user;
  const positionId = `${event.chainId}_${account}`;

  const position = await context.Position.get(positionId);

  context.Position.set({
    id: positionId,
    account: account,
    collateral: position!.collateral,
    borrowed: position!.borrowed + event.params.amount,
    timestamp: BigInt(event.block.timestamp),
    txHash: event.transaction.hash,
  });
});
