import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure that users can create pixel art",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;

    // Create a simple 8x8 pixel art
    let pixels = Array(64).fill(types.uint(0));
    
    let block = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'create-artwork', [
        types.uint(8),
        types.uint(8),
        types.list(pixels)
      ], user1.address)
    ]);

    // First artwork should have ID 0
    block.receipts[0].result.expectOk().expectUint(0);

    // Check artwork data
    let artworkBlock = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'get-artwork', [
        types.uint(0)
      ], user1.address)
    ]);

    let artwork = artworkBlock.receipts[0].result.expectSome();
    assertEquals(artwork['width'], types.uint(8));
    assertEquals(artwork['height'], types.uint(8));
    assertEquals(artwork['owner'], user1.address);
  },
});

Clarinet.test({
  name: "Test animation creation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get('wallet_1')!;

    // Create animation with two frames
    let frameIds = [types.uint(0), types.uint(1)];
    let frameDelays = [types.uint(500), types.uint(500)];

    let block = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'create-animation', [
        types.list(frameIds),
        types.list(frameDelays)
      ], user1.address)
    ]);

    block.receipts[0].result.expectOk().expectUint(0);

    // Verify animation data
    let animationBlock = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'get-animation', [
        types.uint(0)
      ], user1.address)
    ]);

    let animation = animationBlock.receipts[0].result.expectSome();
    assertEquals(animation['owner'], user1.address);
  },
});

Clarinet.test({
  name: "Test collection creation and management",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const user1 = accounts.get('wallet_1')!;
    const user2 = accounts.get('wallet_2')!;

    // Create collection
    let block = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'create-collection', [
        types.ascii("Test Collection"),
        types.ascii("A test collection"),
        types.bool(true)
      ], user1.address)
    ]);

    block.receipts[0].result.expectOk().expectUint(0);

    // Add contributor
    let contributorBlock = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'add-contributor', [
        types.uint(0),
        types.principal(user2.address)
      ], user1.address)
    ]);

    contributorBlock.receipts[0].result.expectOk().expectBool(true);

    // Create and add artwork to collection
    let pixels = Array(64).fill(types.uint(0));
    
    let artworkBlock = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'create-artwork', [
        types.uint(8),
        types.uint(8),
        types.list(pixels)
      ], user1.address)
    ]);

    let addToCollectionBlock = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'add-artwork-to-collection', [
        types.uint(0),
        types.uint(0)
      ], user1.address)
    ]);

    addToCollectionBlock.receipts[0].result.expectOk().expectBool(true);
  },
});

Clarinet.test({
  name: "Test artwork transfer",
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

    // Transfer artwork
    let transferBlock = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'transfer-artwork', [
        types.uint(0),
        types.principal(user2.address)
      ], user1.address)
    ]);

    transferBlock.receipts[0].result.expectOk().expectBool(true);

    // Verify new owner
    let ownerBlock = chain.mineBlock([
      Tx.contractCall('pixel-nest', 'get-artwork-owner', [
        types.uint(0)
      ], user1.address)
    ]);

    ownerBlock.receipts[0].result.expectOk().expectSome().assertEquals(user2.address);
  },
});
