# CHANGELOG

## v1.2.0 (8/8/2016)

- Added `Client#receipt_from_id_and_hash` convenience method

## v1.1.0 (8/6/2016)

- Added `Receipt#valid?` method to verify Merkle tree proof.
- Validates `Receipt` merkle tree and target hash match on import.
- Added support for blockchain subscription API's

## v1.0.0 (8/5/2016)

- Refactor Ruby API to better match the Client, HashItem, Receipt, Confirmation hierarchy.
- Support newly release Chainpoint 2.0 Blockchain receipts
- Drop support for Chainpoint 1.0

## v0.1.0 (8/1/2016)

This is the initial ALPHA quality release.
