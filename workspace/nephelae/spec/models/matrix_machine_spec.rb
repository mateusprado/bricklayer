require File.dirname(__FILE__) + '/../spec_helper'

describe MatrixMachine do
  should_belong_to :zone
  should_belong_to :system_image

  context 'when validating data' do
    before :each do
      # Needed to check for uniqueness of uuid
      Factory(:matrix)
    end

    should_validate_presence_of :uuid, :name
    should_validate_uniqueness_of :uuid
  end
end
