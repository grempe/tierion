module Tierion
  class Hashitem
    include ::HTTParty
    base_uri 'https://hashapi.tierion.com/v1'

    default_timeout 5
    open_timeout 5
    # debug_output $stdout

    attr_reader :receipts
    attr_accessor :debug

    def initialize(uname = ENV['TIERION_USERNAME'], pwd = ENV['TIERION_PASSWORD'])
      @auth = { username: uname, password: pwd }
      @access_token = nil
      @expires_at = Time.now.utc - 1
      @refresh_token = nil
      @receipts = []
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
        hir = HashitemReceipt.new(parsed)
        @receipts << hir
        return hir
      else
        raise_error(response)
      end
    end

    # Retrieve and store the BlockchainReceipt from the API for each
    # HashitemReceipt that does not have one.
    def blockchain_receipts
      @receipts.each do |hir|
        next if hir.blockchain_receipt.is_a?(Tierion::BlockchainReceipt)
        bcr = blockchain_receipt(hir)
        hir.blockchain_receipt = bcr
      end

      @receipts.collect(&:blockchain_receipt).compact
    end

    # Retrieve the blockchain receipt for a specific HashitemReceipt ID
    def blockchain_receipt(hir)
      unless hir.is_a?(Tierion::HashitemReceipt)
        raise ArgumentError, 'is not a HashitemReceipt object'
      end

      auth_refresh unless logged_in?
      options = { headers: { 'Authorization' => "Bearer #{@access_token}" } }
      response = self.class.get("/receipts/#{hir.id}", options)

      if response.success? && response.parsed_response['receipt'].present?
        receipt = JSON.parse(response.parsed_response['receipt'])
        Hashie.symbolize_keys!(receipt)
        BlockchainReceipt.new(receipt)
      else
        return nil
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

    def logged_in?
      @access_token.present? &&
        @refresh_token.present? &&
        @expires_at >= Time.now.utc
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
