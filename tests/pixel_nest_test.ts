Clarinet.test({
  name: "Test artwork creation and deletion",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get('wallet_1')!;
    
    // Create artwork
    let pixels = Array(64).fill(types.uint(0));
    
    let block = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'create-artwork', [
        types.uint(8),
        types.uint(8),
        types.list(pixels)
      ], user1.address)
    ]);

    block.receipts[0].result.expectOk().expectUint(0);

    // Delete artwork
    let deleteBlock = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'delete-artwork', [
        types.uint(0)
      ], user1.address)
    ]);

    deleteBlock.receipts[0].result.expectOk().expectBool(true);

    // Check platform stats
    let statsBlock = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'get-platform-stats', [], user1.address)
    ]);

    statsBlock.receipts[0].result.expectOk().expectTuple({
      'total-artworks': types.uint(0),
      'next-artwork-id': types.uint(1)
    });
  },
});

// [Previous tests remain unchanged...]
