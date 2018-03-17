module Tierion
  module HashApi
    class Receipt < Hash
      include Hashie::Extensions::MergeInitializer
      include Hashie::Extensions::MethodAccess
      include Hashie::Extensions::IndifferentAccess

      def to_pretty_json
        puts JSON.pretty_generate(self)
      end

      def confirmations
        get_confirmations
        @confs
      end

      def confirmation_status(type)
        anchors.each do |a|
          if a['type'] == 'BTCOpReturn'
            if a['sourceId'].present?
              return btc_status(a['sourceId'])
            end
          end
        end
        nil
      end

      # Checks the validity of the Merkle tree proof and
      # return true or false
      def valid?
        return false if targetHash.blank? || merkleRoot.blank?

        # No siblings, single item tree, so the hash
        # should also be the root
        return targetHash == merkleRoot if proof.empty?

        # The target hash (the hash the user submitted)
        # is always hashed in the first cycle through the
        # proofs. After that, the proof_hash value will
        # contain intermediate hashes.
        proof_hash = targetHash

        proof.each do |p|
          h = Digest::SHA256.new
          if p.key?('left')
            h.update hex2bin(p['left'])
            h.update hex2bin(proof_hash)
          elsif p.key?('right')
            h.update hex2bin(proof_hash)
            h.update hex2bin(p['right'])
          else
            return false
          end
          proof_hash = h.hexdigest
        end

        proof_hash == merkleRoot
      end

      private

      def hex2bin(hex)
        [hex.to_s].pack('H*')
      end

      def get_confirmations
        @confs = {} if @confs.blank?

        return {} if anchors.blank?

        anchors.each do |a|
          # allready confirmed this anchor
          next if @confs[a['type']].is_a?(TrueClass)

          case a['type']
          when 'BTCOpReturn'
            # txn_id
            if a['sourceId'].present?
              @confs[a['type']] = btc_op_return_confirmed?(a['sourceId'])
            end
          end
        end

        @confs
      end

      # The transaction could not be found (neither on the blockchain nor
      # among the pending transactions)
      NO_TRANSACTION = 0

      # The tranasction is not valid, as it does not contain the expected OP_RETURN
      INVALID_TRANSACTION = 1

      # The transaction is valid (ie. contains the expected OP_RETURN).
      # However, the transaction is not mined yet
      OP_RETURN = 2

      # The transaction is valid and mined
      TRANSACTION_MINED = 3

      # Return NO_TRANSACTION, INVALID_TRANSACTION, OP_RETURN or TRANSACTION_MINED
      def btc_status(source_id)
        url = "https://blockchain.info/tx-index/#{source_id}?format=json"

        # op_return values begin with 0x6a (op_return code) &
        # 0x20 (length in hex : 32 bytes)
        op_return = ['6a20', merkleRoot].join('')

        response = HTTParty.get(url)

        return NO_TRANSACTION unless response.success?

        return INVALID_TRANSACTION unless response['out'].present?

        return INVALID_TRANSACTION unless response['out'].any? do |o|
          o['script'].present? && o['script'] == op_return
        end

        return (response['block_height'].present? and response['block_height'] > 0) ? TRANSACTION_MINED : OP_RETURN
      end


      # Confirm Bitcoin OP_RETURN anchor
      def btc_op_return_confirmed?(source_id)
        btc_status(source_id) >= OP_RETURN
      end
    end
  end
end
