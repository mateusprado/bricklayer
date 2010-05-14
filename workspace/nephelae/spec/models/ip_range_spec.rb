require 'spec_helper'

describe IpRange do

  should_have_many :ips, :autosave => true, :dependent => :destroy
  should_belong_to :vlan
  
  should_validate_presence_of :address, :mask
  should_validate_numericality_of :mask, :greater_than_or_equal_to => IpRange::MINIMUM_MASK, :less_than_or_equal_to => IpRange::MAXIMUM_MASK
  should_allow_values_for :address, '10.1.2.9', '0.0.0.0', '255.255.255.255'
  should_not_allow_values_for :address, '1.2.9', '-1.0.0.0', '255.255.255.256'

end
