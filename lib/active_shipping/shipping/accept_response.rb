module ActiveMerchant #:nodoc:
  module Shipping
    
    class AcceptResponse < Response
      
      attr_reader :graphic_image
      attr_reader :tracking_number
      
      def initialize(success, message, params = {}, options = {})
        @graphic_image = options[:graphic_image]
        @tracking_number = options[:tracking_number]
        super
      end
      
      #alias_method :digest, :shipment_digest
    end
    
  end
end
