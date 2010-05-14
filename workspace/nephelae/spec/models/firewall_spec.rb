require 'spec_helper'

describe Firewall do
  should_validate_presence_of :ip_address, :zone_id
  should_belong_to :zone
  should_have_many :virtual_machines, :through => :zone
end
