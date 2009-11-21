module ActiveMerchant #:nodoc:
  module Shipping
    
    class ConfirmResponse < Response
      
      attr_reader :transportation_fee, :transportation_fee_currency
      attr_reader :service_options_charges, :service_options_charges_currency
      attr_reader :total_charges, :total_charges_currency
      attr_reader :weight
      attr_reader :shipment_identification_number
      attr_reader :shipment_digest
      
      def initialize(success, message, params = {}, options = {})
        @transportation_fee = options[:transportation_fee]
        @transportation_fee_currency = options[:transportation_fee_currency]
        @service_options_charges = options[:service_options_charges]
        @service_options_charges_currency = options[:service_options_charges_currency]
        @total_charges = options[:total_charges]
        @total_charges_currency = options[:total_charges_currency]
        @weight = options[:weight]
        @shipment_identification_number = options[:hipment_identification_number]
        @shipment_digest = options[:shipment_digest]
        super
      end
      
      alias_method :digest, :shipment_digest
    end
    
  end
end
