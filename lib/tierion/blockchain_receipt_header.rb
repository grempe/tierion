module Tierion
  class BlockchainReceiptHeader < Hashie::Dash
    include Hashie::Extensions::Dash::PropertyTranslation

    property :chainpoint_version, required: true
    property :hash_type, required: true
    property :merkle_root, required: true
    property :tx_id, required: true
    property :timestamp, required: true
  end
end
