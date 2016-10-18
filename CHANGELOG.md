# CHANGELOG

## v1.3.2 (10/18/2016)

- Update to new gem signing cert with 10 year lifetime.
- Add some README info about installing signed gem
- Relax version dependencies for development gems

## v1.3.1 (9/6/2016)

- Merge PR #3, support activesupport 4.x in addition to 5.x

## v1.3.0 (8/9/2016)

- Updated blockchain subscription CRUD methods to support labels and retrieving all subscriptions with `Client#get_block_subscriptions`. You can now have multiple subscription callback endpoints, each with a unique ID.

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
