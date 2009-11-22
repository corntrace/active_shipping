require File.dirname(__FILE__) + '/../../test_helper'
require 'ruby-debug'

class UPSTest < Test::Unit::TestCase
  
  def setup
    @packages  = TestFixtures.packages
    @locations = TestFixtures.locations
    @carrier   = UPS.new(
                   :key => 'key',
                   :login => 'login',
                   :password => 'password'
                 )
    @tracking_response = xml_fixture('ups/shipment_from_tiger_direct')
  end

  def test_build_confirm_request
    @carrier = UPS.new( :key => 'key', :login => 'login', :password => 'password', :test => true)
    assert_raises(ArgumentError) {@carrier.send(:build_confirm_request, @locations[:beverly_hills], @locations[:real_home_as_residential], @packages.values_at(:chocolate_stuff))}
    assert_raises(ArgumentError) {@carrier.send(:build_confirm_request, @locations[:beverly_hills], @locations[:real_home_as_residential], @packages.values_at(:chocolate_stuff), :account_number => '123456')}
    assert_nothing_raised do
      @carrier.send(:build_confirm_request, @locations[:beverly_hills], @locations[:real_home_as_residential], @packages.values_at(:chocolate_stuff), :account_number => '123456', :service_code => '01')
    end
  end

  def test_build_accept_request
    @carrier = UPS.new( :key => 'key', :login => 'login', :password => 'password', :test => true)
    assert_raises(ArgumentError) {@carrier.send(:build_accept_request, '', :comment => "mock_comment")}
    assert_nothing_raised do
      response = @carrier.send(:build_accept_request, "mock_digest", :comment => "mock_comment")
    end
  end

  def test_parse_confirm_response
    response = xml_fixture('ups/confirm_shipping_response')
    @carrier = UPS.new( :key => 'key', :login => 'login', :password => 'password', :test => true)
    assert_nothing_raised do 
      result = @carrier.send :parse_confirm_response, response
      assert_equal false, result.shipment_digest.blank?
    end
  end

  def test_parse_accept_response
    response = xml_fixture('ups/accept_shipping_response')
    @carrier = UPS.new( :key => 'key', :login => 'login', :password => 'password', :test => true)
    assert_nothing_raised do 
      result = @carrier.send :parse_accept_response, response
      assert_equal false, result.graphic_image.blank?
      assert_equal false, result.tracking_number.blank?
    end
  end

  def test_confirm_shipping
    @carrier = UPS.new(:key => 'xxxx', :login => 'xxx', :password => 'xxx', :test => true)
    @carrier.stubs(:commit).returns(xml_fixture('ups/confirm_shipping_response'))
    assert_nothing_raised do
      response = @carrier.confirm_shipping(
        @locations[:beverly_hills],
        @locations[:real_home_as_residential],
        @packages.values_at(:chocolate_stuff),
        :account_number => 'xxx', :service_code => '01'
      )
      assert_equal false, response.blank?
    end
  end

  def test_accept_shipping
    @carrier = UPS.new( :key => 'xxx', :login => 'xxx', :password => 'xxx', :test => true)
    @carrier.stubs(:commit).returns(xml_fixture('ups/confirm_shipping_response'))
    confirm_resp = @carrier.confirm_shipping(
      @locations[:beverly_hills],
      @locations[:real_home_as_residential],
      @packages.values_at(:chocolate_stuff),
      :account_number => 'xxx', :service_code => '01'
    )
    @carrier.stubs(:commit).returns(xml_fixture('ups/accept_shipping_response'))
    assert_nothing_raised do
      accept_resp = @carrier.accept_shipping(confirm_resp.shipment_digest)
    end
  end
  
  def test_initialize_options_requirements
    assert_raises(ArgumentError) { UPS.new }
    assert_raises(ArgumentError) { UPS.new(:login => 'blah', :password => 'bloo') }
    assert_raises(ArgumentError) { UPS.new(:login => 'blah', :key => 'kee') }
    assert_raises(ArgumentError) { UPS.new(:password => 'bloo', :key => 'kee') }
    assert_nothing_raised { UPS.new(:login => 'blah', :password => 'bloo', :key => 'kee') }
  end
  
  def test_find_tracking_info_should_return_a_tracking_response
    @carrier.expects(:commit).returns(@tracking_response)
    assert_equal 'ActiveMerchant::Shipping::TrackingResponse', @carrier.find_tracking_info('1Z5FX0076803466397').class.name
  end
  
  def test_find_tracking_info_should_parse_response_into_correct_number_of_shipment_events
    @carrier.expects(:commit).returns(@tracking_response)
    response = @carrier.find_tracking_info('1Z5FX0076803466397')
    assert_equal 8, response.shipment_events.size
  end
  
  def test_find_tracking_info_should_return_shipment_events_in_ascending_chronological_order
    @carrier.expects(:commit).returns(@tracking_response)
    response = @carrier.find_tracking_info('1Z5FX0076803466397')
    assert_equal response.shipment_events.map(&:time).sort, response.shipment_events.map(&:time)
  end
  
  def test_find_tracking_info_should_have_correct_names_for_shipment_events
    @carrier.expects(:commit).returns(@tracking_response)
    response = @carrier.find_tracking_info('1Z5FX0076803466397')
    assert_equal [ "BILLING INFORMATION RECEIVED",
                   "IMPORT SCAN",
                   "LOCATION SCAN",
                   "LOCATION SCAN",
                   "DEPARTURE SCAN",
                   "ARRIVAL SCAN",
                   "OUT FOR DELIVERY",
                   "DELIVERED" ], response.shipment_events.map(&:name)
  end
  
  def test_add_origin_and_destination_data_to_shipment_events_where_appropriate
    @carrier.expects(:commit).returns(@tracking_response)
    response = @carrier.find_tracking_info('1Z5FX0076803466397')
    assert_equal '175 AMBASSADOR', response.shipment_events.first.location.address1
    assert_equal 'K1N5X8', response.shipment_events.last.location.postal_code
  end
  
  def test_response_parsing
    mock_response = xml_fixture('ups/test_real_home_as_residential_destination_response')
    @carrier.expects(:commit).returns(mock_response)
    response = @carrier.find_rates( @locations[:beverly_hills],
                                    @locations[:real_home_as_residential],
                                    @packages.values_at(:chocolate_stuff))
    assert_equal [ "UPS Ground",
                   "UPS Three-Day Select",
                   "UPS Second Day Air",
                   "UPS Next Day Air Saver",
                   "UPS Next Day Air Early A.M.",
                   "UPS Next Day Air"], response.rates.map(&:service_name)
    assert_equal [992, 2191, 3007, 5509, 9401, 6124], response.rates.map(&:price)
  end
  
  def test_maximum_weight
    assert Package.new(150 * 16, [5,5,5], :units => :imperial).mass == @carrier.maximum_weight
    assert Package.new((150 * 16) + 0.01, [5,5,5], :units => :imperial).mass > @carrier.maximum_weight
    assert Package.new((150 * 16) - 0.01, [5,5,5], :units => :imperial).mass < @carrier.maximum_weight
  end
end
