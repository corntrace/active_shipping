module ActiveMerchant #:nodoc:
  module Shipping
    
    class ConfirmResponse < Response
      
      attr_reader :digest
      
      def initialize(success, message, params = {}, options = {})
        @digest = options[:digest] || options[:shipment_digest]
        super
      end
      
      alias_method :shipment_digest, :digest
    end
    
  end
end
