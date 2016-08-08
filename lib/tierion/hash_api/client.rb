module Tierion
  module HashApi
    class Client
      include ::HTTParty
      base_uri 'https://hashapi.tierion.com/v1'

      default_timeout 5
      open_timeout 5
      # debug_output $stdout

      attr_accessor :hash_items

      def initialize(uname = ENV['TIERION_USERNAME'], pwd = ENV['TIERION_PASSWORD'])
        @auth = { username: uname, password: pwd }
        @access_token = nil
        @expires_at = Time.now.utc - 1
        @refresh_token = nil
        @hash_items = []
        auth
      end

      def auth
        options = { body: @auth }
        response = self.class.post('/auth/token', options)

        if response.success?
          extract_auth_tokens(response)
        else
          raise_error(response)
        end
      end

      def auth_refresh
        if expired_auth?
          options = { body: { 'refreshToken' => @refresh_token } }
          response = self.class.post('/auth/refresh', options)

          if response.success?
            extract_auth_tokens(response)
          else
            raise_error(response)
          end
        else
          auth
        end
      end

      def send(hash)
        unless hash =~ /^[a-f0-9]{64}$/
          raise ArgumentError, 'is not a valid SHA256 hex hash string'
        end

        auth_refresh unless logged_in?
        options = {
          body: { 'hash' => hash },
          headers: { 'Authorization' => "Bearer #{@access_token}" }
        }
        response = self.class.post('/hashitems', options)

        if response.success?
          parsed = response.parsed_response
          Hashie.symbolize_keys!(parsed)
          parsed.merge!({hash: hash})
          h = Tierion::HashApi::HashItem.new(parsed)
          @hash_items << h
          return h
        else
          raise_error(response)
        end
      end

      # Get a Receipt for each HashItem that doesn't have one
      # and return the collection of Receipts.
      def receipts
        @hash_items.each do |h|
          next if h.receipt.present?
          h.receipt = receipt(h)
        end

        @hash_items.collect(&:receipt).compact
      end

      # Retrieve the receipt for a specific HashItem
      def receipt(h)
        unless h.is_a?(Tierion::HashApi::HashItem)
          raise ArgumentError, 'is not a Tierion::HashApi::HashItem object'
        end

        auth_refresh unless logged_in?
        options = { headers: { 'Authorization' => "Bearer #{@access_token}" } }
        response = self.class.get("/receipts/#{h.id}", options)

        if response.success? && response.parsed_response['receipt'].present?
          receipt = JSON.parse(response.parsed_response['receipt'])
          Hashie.symbolize_keys!(receipt)

          if receipt.key?(:type) || receipt.key?('@type')
            r = Tierion::HashApi::Receipt.new(receipt)
            if h.hash == r.targetHash && r.valid?
              return r
            else
              raise 'Invalid Receipt. Merkle tree proof validation failed.'
            end
          else
            raise 'Invalid Receipt. Missing type key. Old chainpoint?'
          end
        else
          return nil
        end
      end

      # Retrieve a receipt from its HashItem#id and the original SHA256 hash
      # used to create that HashItem.
      def receipt_from_id_and_hash(id, hash)
        hi = Tierion::HashApi::HashItem.new(id: id, hash: hash, timestamp: Time.now.utc.to_i)
        receipt(hi)
      end

      def logged_in?
        @access_token.present? &&
          @refresh_token.present? &&
          @expires_at >= Time.now.utc
      end

      def create_block_subscription(callback_url)
        auth_refresh unless logged_in?
        options = {
          body: { 'callbackUrl' => callback_url },
          headers: { 'Authorization' => "Bearer #{@access_token}" }
        }
        response = self.class.post('/blocksubscriptions', options)

        if response.success?
          parsed = response.parsed_response
          Hashie.symbolize_keys!(parsed)
          return parsed
        else
          raise_error(response)
        end
      end

      def get_block_subscription(id)
        auth_refresh unless logged_in?
        options = {
          headers: { 'Authorization' => "Bearer #{@access_token}" }
        }
        response = self.class.get("/blocksubscriptions/#{id}", options)

        if response.success?
          parsed = response.parsed_response
          Hashie.symbolize_keys!(parsed)
          return parsed
        else
          raise_error(response)
        end
      end

      def update_block_subscription(id, callback_url)
        auth_refresh unless logged_in?
        options = {
          body: { 'callbackUrl' => callback_url },
          headers: { 'Authorization' => "Bearer #{@access_token}" }
        }
        response = self.class.put("/blocksubscriptions/#{id}", options)

        if response.success?
          parsed = response.parsed_response
          Hashie.symbolize_keys!(parsed)
          return parsed
        else
          raise_error(response)
        end
      end

      def delete_block_subscription(id)
        auth_refresh unless logged_in?
        options = {
          headers: { 'Authorization' => "Bearer #{@access_token}" }
        }
        response = self.class.delete("/blocksubscriptions/#{id}", options)

        if response.success?
          parsed = response.parsed_response
          Hashie.symbolize_keys!(parsed)
          return parsed
        else
          raise_error(response)
        end
      end

      private

      def raise_error(response)
        if response['error'].present?
          raise response['error']
        else
          raise 'Unknown Fatal Error'
        end
      end


      def expired_auth?
        @access_token.present? &&
          @refresh_token.present? &&
          @expires_at < Time.now.utc
      end

      def extract_auth_tokens(resp)
        if resp &&
           resp.parsed_response &&
           resp.parsed_response.is_a?(Hash) &&
           resp.parsed_response.key?('access_token') &&
           resp.parsed_response.key?('refresh_token') &&
           resp.parsed_response.key?('expires_in')
          @access_token = resp.parsed_response['access_token']
          @refresh_token = resp.parsed_response['refresh_token']
          @expires_at = Time.now.utc + resp.parsed_response['expires_in']
          return true
        end
      end
    end
  end
end
