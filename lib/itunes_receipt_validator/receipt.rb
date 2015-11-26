##
# ItunesReceiptValidator
module ItunesReceiptValidator
  ##
  # ItunesReceiptValidator::Receipt
  class Receipt
    extend Forwardable

    attr_accessor :shared_secret
    attr_reader :receipt

    def initialize(receipt, options = {})
      @receipt = receipt
      @shared_secret = options.fetch(:shared_secret, nil)
      local
      yield self if block_given?
    end

    def bundle_id
      @bundle_id = local.receipt.fetch(style == :unified ? :bundle_id : :bid)
    end

    def transactions
      @transactions = TransactionsProxy.import(
        local_transactions_source, self
      )
    end

    def latest_transactions
      @latest_transactions = TransactionsProxy.import(
        remote_transactions_source, self
      )
    end

    def latest_receipt
      @latest_receipt = remote.json.fetch :latest_receipt
    end

    def local
      @local ||= ItunesReceiptDecoder.new receipt, expand_timestamps: true
    rescue ItunesReceiptDecoder::DecodingError => e
      raise LocalDecodingError, e.message
    end

    def_delegators :local, :sandbox?, :production?, :style

    def remote
      @remote ||= Remote.new receipt,
                             shared_secret: shared_secret,
                             sandbox: sandbox?
    end

    private

    def local_transactions_source
      style == :unified ? local.receipt.fetch(:in_app) : [local.receipt]
    end

    def remote_transactions_source
      if style == :unified
        remote.json.fetch(:latest_receipt_info)
      else
        [remote.json.fetch(:latest_receipt_info)]
      end
    end
  end
end
