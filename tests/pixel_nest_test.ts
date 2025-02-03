// Previous test content remains unchanged...

Clarinet.test({
  name: "Test artwork transfer restrictions",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get('wallet_1')!;
    const user2 = accounts.get('wallet_2')!;

    // Create artwork
    let pixels = Array(64).fill(types.uint(0));
    
    let block = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'create-artwork', [
        types.uint(8),
        types.uint(8),
        types.list(pixels)
      ], user1.address)
    ]);

    // Enable transfer restriction
    let restrictBlock = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'set-artwork-transfer-restriction', [
        types.uint(0),
        types.bool(true)
      ], user1.address)
    ]);

    restrictBlock.receipts[0].result.expectOk().expectBool(true);

    // Attempt transfer while restricted
    let transferBlock = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'transfer-artwork', [
        types.uint(0),
        types.principal(user2.address)
      ], user1.address)
    ]);

    // Should fail due to restriction
    transferBlock.receipts[0].result.expectErr().expectUint(105);

    // Disable restriction
    let unrestrictBlock = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'set-artwork-transfer-restriction', [
        types.uint(0),
        types.bool(false)
      ], user1.address)
    ]);

    // Now transfer should succeed
    let successTransferBlock = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'transfer-artwork', [
        types.uint(0),
        types.principal(user2.address)
      ], user1.address)
    ]);

    successTransferBlock.receipts[0].result.expectOk().expectBool(true);
  },
});
