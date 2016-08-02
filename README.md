# Tierion

A simple API client for the [Tierion Hash API](https://tierion.com/docs/hashapi).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tierion'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tierion

## Usage

Shell commands start with a `$`, Ruby console commands start with `>`.

Instantiate a new API client

```
> t = Tierion::Hashitem.new('me@example.com', 'mypassword')
```

You can also set the username and password in environment
variables.

```
$ export TIERION_USERNAME=me@example.com
$ export TIERION_PASSWORD=my_pass
```

```
> t = Tierion::Hashitem.new
```

Create the hash you want to record on the blockchain
and send it.

```
> my_hash = Digest::SHA256.hexdigest('foo')
=> "2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae">

> t.send(my_hash)
=> Tierion::HashitemReceipt ...
```

Examine the array of `HashitemReceipt` objects stored in the
client. This is the only place to find the hash item
ID's. You probably want to store these somewhere in your DB
since this client is ephemeral and there is no way to
retrieve these ID's later.

```
> t.receipts
=> [Tierion::HashitemReceipt..., Tierion::HashitemReceipt ...]
```

Get one HashitemReceipt to work on

```
> h = t.receipts.first
```

For convenience you can use `Hashitem#time` to get
the timestamp as a `Time` object (UTC time)

```
> h.time
=> 2016-08-01 17:56:11 UTC
```

You can retrieve an individual `BlockchainReceipt` by
passing a `HashitemReceipt` as the arg to `Hashitem#blockchain_receipt`

```
> t.blockchain_receipt(h)
=> Tierion::BlockchainReceipt ...
```

Or, call `Hashitem#blockchain_receipts` to loop through
each `HashitemReceipt` submitted in this session
and collect `BlockchainReceipts` for each from the
API.

Remember that these are not available until
processed and sent to the blockchain so you may need to
call this again later to populate this Array fully.

```
> t.blockchain_receipts
=> [Tierion::BlockchainReceipt..., Tierion::BlockchainReceipt ...]
```

Get one `BlockchainReceipt` to work on

```
> b = t.blockchain_receipts.first
=> Tierion::BlockchainReceipt ...
```

A `BlockchainReceipt` object has a number of properties
which are populated from the API.

```
> b.header
> b.target
> b.extra

# The URL's that are generated for confirming this txn on the blockchain.
> b.confirmation_url
> b.confirmation_url_json
```

You can also query whether the transaction associated
with a `BlockchainReceipt` has actually been confirmed on the
blockchain. Once confirmed a data structure from the
third-party `blockchain.info` API will also be populated
with the full transaction data.

`BlockchainReceipt`s can take quite a while to be confirmed.

```
> b.confirmed?
=> true

# A hash of data from the blockchain.info API
> b.blockchain_info_confirmation
=> { ... }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then,
run `rake test` to run the tests. You can also run `bin/console` for an
interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

You can run the Command Line Interface (CLI) in development
with `bundle exec exe/tierion`. (TODO : Implement CLI)

The formal release process can be found in [RELEASE.md](https://github.com/grempe/tierion/blob/master/RELEASE.md)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/grempe/tierion. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
