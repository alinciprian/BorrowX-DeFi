import assert from "assert";
import { 
  TestHelpers,
  BorrowX_CollateralDeposited
} from "generated";
const { MockDb, BorrowX } = TestHelpers;

describe("BorrowX contract CollateralDeposited event tests", () => {
  // Create mock db
  const mockDb = MockDb.createMockDb();

  // Creating mock for BorrowX contract CollateralDeposited event
  const event = BorrowX.CollateralDeposited.createMockEvent({/* It mocks event fields with default values. You can overwrite them if you need */});

  it("BorrowX_CollateralDeposited is created correctly", async () => {
    // Processing the event
    const mockDbUpdated = await BorrowX.CollateralDeposited.processEvent({
      event,
      mockDb,
    });

    // Getting the actual entity from the mock database
    let actualBorrowXCollateralDeposited = mockDbUpdated.entities.BorrowX_CollateralDeposited.get(
      `${event.chainId}_${event.block.number}_${event.logIndex}`
    );

    // Creating the expected entity
    const expectedBorrowXCollateralDeposited: BorrowX_CollateralDeposited = {
      id: `${event.chainId}_${event.block.number}_${event.logIndex}`,
      user: event.params.user,
      amount: event.params.amount,
    };
    // Asserting that the entity in the mock database is the same as the expected entity
    assert.deepEqual(actualBorrowXCollateralDeposited, expectedBorrowXCollateralDeposited, "Actual BorrowXCollateralDeposited should be the same as the expectedBorrowXCollateralDeposited");
  });
});
