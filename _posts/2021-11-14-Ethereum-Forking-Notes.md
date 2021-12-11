---
title: Ethereum Forking Notes
subtitle: Notes on how different clients handle hardforks and softforks
tags: [ethereum, blockchain, distributed computing]
---

# Ethereum Forking Notes

Probability of a Fork Occuring

$$
P\left(f o r k \mid t_{B}=600\right)=1-e^{\frac{-t_{90} t h}{600}}
$$

Based on the above, the probability for a fork to occur is $$P(f ork) = 1.915%$$

for a propagation time of $$t90th = 11.6seconds$$

We note that while the network size (N) effect over theblock propagation time
(t50th) is logarithmic,the block size’s(B) effect is linear.

### Go Ethereum

[https://github.com/ethereum/go-ethereum/commit/82538dc0c04f03bbc4e3eab953ad2c1bd67ef847.patch](/n-L9O9AYRbGo0Z9oqpQKJA)

```lang=go
// We're about to replace a transaction. The reorg does a more thorough
// analysis of what to remove and how, but it runs async. We don't want to
// do too many replacements between reorg-runs, so we cap the number of
// replacements to 25% of the slots
if pool.changesSinceReorg > int(pool.config.GlobalSlots/4) {
    throttleTxMeter.Mark(1)
    return false, ErrTxPoolOverflow
}
```

```lang=go
// throttleTxMeter counts how many transactions are rejected due to too-many-changes between
// txpool reorgs.
throttleTxMeter = metrics.NewRegisteredMeter("txpool/throttle", nil)
// reorgDurationTimer measures how long time a txpool reorg takes.
reorgDurationTimer = metrics.NewRegisteredTimer("txpool/reorgtime", nil)
// dropBetweenReorgHistogram counts how many drops we experience between two reorg runs. It is expected
// that this number is pretty low, since txpool reorgs happen very frequently.
dropBetweenReorgHistogram = metrics.NewRegisteredHistogram("txpool/dropbetweenreorg", nil, metrics.NewExpDecaySample(1028, 0.015))
```

source[https://github.com/ethereum/go-ethereum/commit/82538dc0c04f03bbc4e3eab953ad2c1bd67ef847.diff](https://github.com/ethereum/go-ethereum/commit/82538dc0c04f03bbc4e3eab953ad2c1bd67ef847.diff)

https://github.com/ethers-io/ethers.js/blob/7175e2e99c2747e8d2314feb407bf0a0f9371ece/packages/abstract-provider/src.ts/index.ts#L146

### The Graph

[https://github.com/graphprotocol/graph-node/pull/1801](https://github.com/graphprotocol/graph-node/pull/1801)

## Eth2

[https://github.com/fjl/p2p-drafts/blob/c20e4c3cb5778cce26744e5275ca2b3f9a47b690/merge-sync/merge-sync.md#reorg-processing-and-state-availability](https://github.com/fjl/p2p-drafts/blob/c20e4c3cb5778cce26744e5275ca2b3f9a47b690/merge-sync/merge-sync.md#reorg-processing-and-state-availability)

## Reorg processing and state availability

It is common knowledge that the application state of eth1 can become quite
large. As such, eth1 clients usually only store exactly one full copy of this
state.

In order to make state synchronization work, the application state of the latest
finalized block BF must be available for download. We therefore recommend that
clients which store exactly one full copy of the state should store the state of
BF.

For the tree of non-finalized blocks beyond BF, the state diff of each block can
be held in main memory. As new blocks are finalized, the client applies their
diffs to the database, moving the persistent state forward. Storing diffs in
memory allows for efficient reorg processing: when the eth2 client detects a
reorg from block bx to block by, it first determines the common ancestor ba. It
can then submit all blocks Ba+1…By for processing. When the eth1 client detects
that a block has already been processed because its state is available as a diff
in memory, it can skip EVM processing of the block and just move its head state
reference to the new block.

While reorgs below BF cannot happen during normal operation of the beacon chain,
it may still be necessary to roll back to an earlier state when EVM processing
flaws cause the client to deviate from the canonical chain. As a safety net for
this exceptional case, we recommend that eth1 clients to maintain a way to
manually reorg up to 90,000 blocks (roughly 2 weeks), as this would provide
sufficient time to fix issues.

To make this 'manual intervention reorg' work, eth1 client can maintain backward
diffs in a persistent store. If an intervention is requested, these diffs can be
incrementally applied to the state of BF, resetting the client to an earlier
state.

## Issues

In early review of this scheme, two issues were discovered. Both stem from our
misunderstanding of eth2 finalization semantics.

(1) Since eth2 finalizes blocks only on epoch boundaries, it wants to call
final(B) only for epoch blocks. This could be handled a bit better by also using
proc(B) in the sync trigger.

(2) While finalization will work within ~64 blocks in the happy case, it can
take up to 2 weeks to finalize in the event of a network partition. Since the
maximum number of non-finalized blocks is so much larger than we initially
anticipated, it will not be possible to use BF as the persistent state block.

We have decided to tackle this issue in the following way:

- At head H, define the 'calcified' block BC with C = max(H-512, F). This puts
  an upper bound of 512 blocks on the number of states kept in memory.
- Define that clients should keep the state of BC in persistent storage.
- Use BC as the initial sync target. This has implications on the sync trigger
  because the eth1 client can no longer rely on final(B) to start sync (BC may
  be non-final).
- Add a new call \***\*reset(B)\*\*** to reset the eth1 client to a historical
  block. Require that clients must be able to satisfy any reset in range BF…BH.
  They will probably have to implement something like the persistent reverse
  diffs recommended in the reorg section.

Adding the calcified block also adds some tricky new corner cases and failure
modes. In particular, if the eth1 client just performed snap sync, it will not
be able to reorg below BC, because reverse diffs down to BF will not be
available. We may solve this by recommending that nodes should attempt snap sync
if reset(B) cannot be satisfied. For sure, some nodes will be synced enough to
serve the target state. In the absolute worst case, we need to make reverse
diffs available for download in snap sync.

# Fork choice

[https://hackmd.io/QFm6Ih\_-Si6_kSLCWTZQyw?view](https://hackmd.io/QFm6Ih_-Si6_kSLCWTZQyw?view)

_Notes:_

- **Eth1 data**: Eth1 data included in a block must correspond to the Eth1 state
  produced by the execution part of the parent block. This acts as an additional
  filter on the block subtree under consideration for the beacon block fork
  choice.

## Helpers

### `get_eth1_data`

Let `get_eth1_data(application_state_root: Bytes32) -> Eth1Data` be the function
that returns the
[`Eth1Data`](https://github.com/ethereum/eth2.0-specs/blob/dev/specs/phase0/beacon-chain.md#eth1data)
obtained from the application state specified by `application_state_root`.

_Note_: This is a function of the state of the beacon chain deposit contract. It
can be read from the eth1 state and/or logs.

### `is_valid_eth1_data`

Used by fork-choice handler, `on_block`, to

```python=
def is_valid_eth1_data(store: Store, block: BeaconBlock) -> boolean:
    parent_state = store.block_states[block.parent_root]
    expected_eth1_data = get_eth1_data(parent_state.application_state_root)
    actual_eth1_data = block.body.eth1_data

    is_correct_root = expected_eth1_data.deposit_root == actual_eth1_data.deposit_root
    is_correct_count = expected_eth1_data.deposit_count == actual_eth1_data.deposit_count
    return is_correct_root and is_correct_count
```

## Updated fork-choice handlers

### `on_block`

_Note_: The only modification is the addition of the `Eth1Data` validity
assumption.

```python=
def on_block(store: Store, signed_block: SignedBeaconBlock) -> None:
    block = signed_block.message
    # Parent block must be known
    assert block.parent_root in store.block_states
    # Make a copy of the state to avoid mutability issues
    pre_state = copy(store.block_states[block.parent_root])
    # Blocks cannot be in the future. If they are, their consideration must be delayed until the are in the past.
    assert get_current_slot(store) >= block.slot

    # Check that block is later than the finalized epoch slot (optimization to reduce calls to get_ancestor)
    finalized_slot = compute_start_slot_at_epoch(store.finalized_checkpoint.epoch)
    assert block.slot > finalized_slot
    # Check block is a descendant of the finalized block at the checkpoint finalized slot
    assert get_ancestor(store, block.parent_root, finalized_slot) == store.finalized_checkpoint.root

    # [Added] Check that Eth1 data is correct
    assert is_valid_eth1_data(store, block)

    # Check the block is valid and compute the post-state
    state = pre_state.copy()
    state_transition(state, signed_block, True)
    # Add new block to the store
    store.blocks[hash_tree_root(block)] = block
    # Add new state for this block to the store
    store.block_states[hash_tree_root(block)] = state

    # Update justified checkpoint
    if state.current_justified_checkpoint.epoch > store.justified_checkpoint.epoch:
        if state.current_justified_checkpoint.epoch > store.best_justified_checkpoint.epoch:
            store.best_justified_checkpoint = state.current_justified_checkpoint
        if should_update_justified_checkpoint(store, state.current_justified_checkpoint):
            store.justified_checkpoint = state.current_justified_checkpoint

    # Update finalized checkpoint
    if state.finalized_checkpoint.epoch > store.finalized_checkpoint.epoch:
        store.finalized_checkpoint = state.finalized_checkpoint

        # Potentially update justified if different from store
        if store.justified_checkpoint != state.current_justified_checkpoint:
            # Update justified if new justified is later than store justified
            if state.current_justified_checkpoint.epoch > store.justified_checkpoint.epoch:
                store.justified_checkpoint = state.current_justified_checkpoint
                return

            # Update justified if store justified is not in chain with finalized checkpoint
            finalized_slot = compute_start_slot_at_epoch(store.finalized_checkpoint.epoch)
            ancestor_at_finalized_slot = get_ancestor(store, store.justified_checkpoint.root, finalized_slot)
            if ancestor_at_finalized_slot != store.finalized_checkpoint.root:
                store.justified_checkpoint = state.current_justified_checkpoint
```

#### Importing a very large Side Fork

Tests that importing a very large side fork, which is larger than the canon
chain, but where the difficulty per block is kept low: this means that it will
not overtake the 'canon' chain until after it's passed canon by about 200
blocks.

Details at:

- https://github.com/ethereum/go-ethereum/issues/18977
- https://github.com/ethereum/go-ethereum/pull/18988

[source, https://github.com/ledgerwatch/erigon/commit/0953fd42cb30491625ce8f4f7c4e83b67dcfd5de#diff-5990e8d82dabd4aef2523b974606fcc515eb6bc0e10b35852aa6085d5fa31018L2174](https://github.com/ledgerwatch/erigon/commit/0953fd42cb30491625ce8f4f7c4e83b67dcfd5de#diff-5990e8d82dabd4aef2523b974606fcc515eb6bc0e10b35852aa6085d5fa31018L2174)

### Modifying Blocks

```go=
// OffsetTime modifies the time instance of a block, implicitly changing its
// associated difficulty. It's useful to test scenarios where forking is not
// tied to chain length directly.
func (b *BlockGen) OffsetTime(seconds int64) {
	b.header.Time.Add(b.header.Time, new(big.Int).SetInt64(seconds))
	if b.header.Time.Cmp(b.parent.Header().Time) <= 0 {
		panic("block time out of range")
	}
```

### Block Number

```js
var Utils = function () {
  s;
  this.isMainNet =
    eth.getBlock(0).hash ===
    '0xd4e56740f876aef8c010b86a40d5f56745a118d0906a34e69aec8c0db1cb8fa3';
  this.isTestNet =
    eth.getBlock(0).hash ===
    '0x0cd786a2425d16f152c658316c423e6ce1181e15c3295826d7c9904cba9ce303';
};
```

https://github.com/ethereum/EIPs/issues/161

```go
common.HexToHash("05bef30ef572270f654746da22639a7a0c97dd97a7050b9e252391996aaeb689"): true,
	common.HexToHash("7d05d08cbc596a2e5e4f13b80a743e53e09221b5323c3a61946b20873e58583f"): true,
```

## Fork ID

[Fork ID EIP 2124](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-2124.md)

> github.com/ethereum/EIPs/blob/master/EIPS/eip-2124.md

```go
// ID is a fork identifier as defined by EIP-2124.
type ID struct {
	Hash [4]byte // CRC32 checksum of the genesis block and passed fork block numbers
	Next uint64  // Block number of the next upcoming fork, or 0 if no forks are known
```

## Hardforks

| ChainID             | 1                                                                  |
| ------------------- | ------------------------------------------------------------------ |
| HomesteadBlock      | 1,150,000                                                          |
| DAOForkBlock        | 1,920,000                                                          |
| DAOForkSupport      | true,                                                              |
| EIP150Block         | 2,463,000                                                          |
| EIP150Hash          | 0x2086799aeebeae135c246c65021c82b4e15a2c451340993aacfd2751886514f0 |
| EIP155Block         | 2,675,000                                                          |
| EIP158Block         | 2,675,000                                                          |
| ByzantiumBlock      | 4,370,000                                                          |
| ConstantinopleBlock | 7,280,000                                                          |
| PetersburgBlock     | 7,280,000                                                          |
| IstanbulBlock       | 9,069,000                                                          |
| MuirGlacierBlock    | 9,200,000                                                          |
| BerlinBlock         | 12,244,000                                                         |
| LondonBlock         | 12,965,000                                                         |
| ArrowGlacierBlock   | 13,773,000                                                         |
