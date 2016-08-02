module Tierion
  class BlockchainReceipt < Hashie::Dash
    include Hashie::Extensions::Dash::PropertyTranslation

    property :header, required: true, transform_with: ->(v) {
      BlockchainReceiptHeader.new(v)
    }

    property :target, required: true, transform_with: ->(v) {
      BlockchainReceiptTarget.new(v)
    }

    property :extra, required: false, default: []

    property :blockchain_info_confirmation, required: false, default: nil

    # Output clean JSON in a format that works with the Blockchain
    # Receipt validator at https://tierion.com/validate
    def to_pretty_json
      puts JSON.pretty_generate(self)
    end

    # Recalculate the merkle tree to ensure the receipt is valid
    def valid?
      # TODO
    end

    # Make an API call to check if the tx_id is a confirmed Transaction
    # on the Blockchain and contains the expected OP_RETURN value with
    # the merkle_root from this receipt.
    def confirmed?
      return false if header.blank? || header.tx_id.blank?
      return false if header.merkle_root.blank?
      response = HTTParty.get(confirmation_url_json)

      if response.success? && response['out'].present?
        # op_return values begin with 0x6a (op_return code) &
        # 0x20 (hex length in bytes of string)
        expected_op_return_value = ['6a20', header.merkle_root].join('')
        confirmed = response['out'].any? do |o|
          o['script'].present? && o['script'] == expected_op_return_value
        end

        # store the parsed output from blockchain.info
        self.blockchain_info_confirmation = response.parsed_response if confirmed
        return confirmed
      else
        false
      end
    end

    def confirmation_url
      return nil if header.blank? || header.tx_id.blank?
      "https://blockchain.info/tx-index/#{header.tx_id}"
    end

    def confirmation_url_json
      return nil if header.blank? || header.tx_id.blank?
      "#{confirmation_url}?format=json"
    end
  end
end
