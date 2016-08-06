module Tierion
  module HashApi
    class HashItem < Hashie::Dash
      include Hashie::Extensions::Dash::PropertyTranslation

      property :hash, required: true
      property :id, from: :receiptId, required: true
      property :timestamp, required: true
      property :receipt, required: false, default: nil

      def time
        timestamp.is_a?(Integer) ? Time.at(timestamp).utc : nil
      end
    end
  end
end
