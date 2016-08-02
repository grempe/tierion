module Tierion
  class HashitemReceipt < Hashie::Dash
    include Hashie::Extensions::Dash::PropertyTranslation

    property :id, from: :receiptId, required: true
    property :timestamp, required: true
    property :blockchain_receipt, required: false, default: nil

    def time
      timestamp.is_a?(Integer) ? Time.at(timestamp).utc : nil
    end
  end
end
