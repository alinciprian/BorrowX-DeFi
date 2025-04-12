import { BorrowX } from "generated";

BorrowX.CollateralDeposited.handler(async ({ event, context }) => {
  const positionId = `${event.chainId}_${event.params.user}`;

  let position = await context.Position.get(positionId);
  if (position) {
    position = {
      ...position,
      collateral: position.collateral + event.params.amount,
    };
  } else {
    position = {
      id: positionId,
      account: event.params.user,
      collateral: event.params.amount,
      borrowed: BigInt(0),
      timestamp: BigInt(event.block.timestamp),
      txHash: event.transaction.hash,
    };
  }

  context.Position.set(position);
});
