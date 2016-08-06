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

      # Confirm Bitcoin OP_RETURN anchor
      def btc_op_return_confirmed?(source_id)
        url = "https://blockchain.info/tx-index/#{source_id}?format=json"

        # op_return values begin with 0x6a (op_return code) &
        # 0x20 (length in hex : 32 bytes)
        op_return = ['6a20', merkleRoot].join('')

        response = HTTParty.get(url)

        if response.success? && response['out'].present?
          has_op_return = response['out'].any? do |o|
            o['script'].present? && o['script'] == op_return
          end

          return has_op_return
        else
          false
        end
      end
    end
  end
end
