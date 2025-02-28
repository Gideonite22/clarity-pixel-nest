// Previous test content remains unchanged...

Clarinet.test({
  name: "Test artwork metadata operations",
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

    // Set metadata
    let metadataBlock = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'set-artwork-metadata', [
        types.uint(0),
        types.some(types.ascii("Test Artwork")),
        types.some(types.ascii("A test artwork description")),
        types.list([types.ascii("test"), types.ascii("art")])
      ], user1.address)
    ]);

    metadataBlock.receipts[0].result.expectOk().expectBool(true);
  },
});
