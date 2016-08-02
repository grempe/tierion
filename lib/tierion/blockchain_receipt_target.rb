module Tierion
  class BlockchainReceiptTarget < Hashie::Dash
    include Hashie::Extensions::Dash::PropertyTranslation

    property :target_hash, required: true
    property :target_proof, required: true
    property :target_uri, required: false
  end
end
