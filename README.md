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
> t = Tierion::HashApi::Client.new('me@example.com', 'mypassword')
```

You can also set the username and password in environment
variables...

```
$ export TIERION_USERNAME=me@example.com
$ export TIERION_PASSWORD=my_pass
```

... and call it without hardcoding your credentials.

```
> t = Tierion::HashApi::Client.new
```

Create the hash you want to record on the blockchain
and send it.

```
> my_hash = Digest::SHA256.hexdigest('foo')
=> "2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae">

> t.send(my_hash)
=> Tierion::HashApi::HashItem ...
```

Now you can take a look at the Array of `HashItem`s.

```
> t.hash_items
=> [Tierion::HashApi::HashItem ..., Tierion::HashApi::HashItem ...]
```

Within the `Tierion::HashApi::HashItem` objects is the only place you
can find the hash item ID's for hashes you've sent. You will probably want
to store these somewhere in your DB since this client instance is ephemeral
and there is no way to retrieve these ID's later.

Let's grab a single `Tierion::HashApi::HashItem` to work on:

```
> h = t.hash_items.first
```

By default the `HashItem#timestamp` value is an Integer representing
the seconds since the UNIX epoch. For convenience you can use `HashItem#time` to get the `timestamp` as a Ruby `Time` object (UTC time).

```
> h.timestamp
=> 1470448435
> h.time
=> 2016-08-06 01:53:55 UTC
```

You can retrieve an individual `Tierion::HashApi::Receipt`
for this `HashItem` by passing the `Hashitem` instance as
an arg to `Client#receipt`

```
> t.receipt(h)
=> Tierion::HashApi::Receipt ...
```

Or, call `Client#receipts` to loop through each `Hashitem`
submitted in this session and collect and cache `Receipts`
for each from the API.

Remember that `Receipt`s are not available until
processed and sent to the blockchain so you may need
to call this again to get the `Reciept` for every `HashItem`.

```
> t.receipts
=> [Tierion::HashApi::Receipt ..., Tierion::HashApi::Receipt ...]
```

Get one `Tierion::HashApi::Receipt` to work on

```
> r = t.receipts.first
=> Tierion::HashApi::Receipt ...
```

A `Tierion::HashApi::Receipt` object has a number of properties
which are populated from the API. Here is an example:

```
> r = t.receipts.first
=> {
  "@context"=>"https://w3id.org/chainpoint/v2",
  "type"=>"ChainpointSHA256v2",
  "targetHash"=>"2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae",
  "merkleRoot"=>"326c0c924a162c8637b8fa392add7c8c98f64f5194f3d2591caf88d7b0b956bd",
  "proof"=>[
    {
      "left"=>"c108bfba805d899faa0ef53b0c064fad650249f6a648fec2bc79fd563106b1f8"
    }
  ],
  "anchors"=>[
    {
      "type"=>"BTCOpReturn",
      "sourceId"=>"579dce214fe0242e3397c9a988622f35b5ee91cef5068b0895a0bbe2c7797b9a"
    }
  ]
}
```

The `Receipt` returns `anchors` which represent one or more trust
anchors where your hash has been stored. Currently, the only `anchor`
returned is `BTCOpReturn` which also gives you a `sourceId`
attribute. This represents the Bitcoin blockchain's OP_RETURN anchor,
with the `sourceId` representing the BTC transaction ID.

You can also query whether the transaction associated with a `Receipt`
has actually been confirmed on a trust anchor with a call to
`Receipt#confirmations`. This will query each supported trust anchor
to determine whether or not the expected hash can be found. This depends
on an API call to a different third-party site for each anchor. This call
will return a hash with the supported trust anchors as the key and a `Boolean` to indicate if the confirmation was successful for that anchor.

`Receipt`s can take quite a while to be confirmed. Possibly several hours.
So, be patient.

```
> r.confirmations
=> {"BTCOpReturn"=>true}
```

You can of course also manually confirm that a hash is
visible at the Transaction ID (`sourceId`) appropriate
for your trust anchor. For example, for Bitcoin you can
search for the `sourceId` at a URL like:

[https://blockchain.info/tx/579dce214fe0242e3397c9a988622f35b5ee91cef5068b0895a0bbe2c7797b9a](https://blockchain.info/tx/579dce214fe0242e3397c9a988622f35b5ee91cef5068b0895a0bbe2c7797b9a)

Or just paste the transaction ID into the search field at [https://blockchain.info](https://blockchain.info).

Once you are looking at the transaction info page, you want to
look for the `OP_RETURN` part of the page, and your hash should be
there, with a `326c` prefix followed by the 32 byte (64 hex characters)
hash value you originally submitted. The prefix represents the hex values
`0x32` and `0x6c` which are the OP_RETURN special code, and the byte length in hex of the OP_RETURN value (your hash).

You can get a pretty JSON representation of the `Receipt` by calling
the `Receipt#to_pretty_json` method.

```
> r.to_pretty_json
{
  "@context": "https://w3id.org/chainpoint/v2",
  "type": "ChainpointSHA256v2",
  "targetHash": "2c26b46b68ffc68ff99b453c1d30413413422d706483bfa0f98a5e886266e7ae",
  "merkleRoot": "326c0c924a162c8637b8fa392add7c8c98f64f5194f3d2591caf88d7b0b956bd",
  "proof": [
    {
      "left": "c108bfba805d899faa0ef53b0c064fad650249f6a648fec2bc79fd563106b1f8"
    }
  ],
  "anchors": [
    {
      "type": "BTCOpReturn",
      "sourceId": "579dce214fe0242e3397c9a988622f35b5ee91cef5068b0895a0bbe2c7797b9a"
    }
  ]
}
```

You can validate this JSON representation of the receipt by
submitting it to the [Tierion validation](https://tierion.com/validate)
web page.

## TODO

- Add blockchain receipt subscription functionality.


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
