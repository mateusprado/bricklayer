require File.dirname(__FILE__) + '/../spec_helper'

describe SystemImage do
  should_validate_presence_of :code, :name
  should_validate_numericality_of :minimum_memory, :minimum_hdd, :minimum_cpus, :greater_than => 0
  should_validate_inclusion_of :code, :in => SystemImage::CODES
  should_validate_inclusion_of :architecture, :in => [32, 64]

  should_have_many :matrix_machines
  should_have_many :virtual_machines

  context "find" do
    before do
      SystemImage.delete_all
    end

    it "should order by name" do
      z = Factory(:centos, :name => "Z")
      a = Factory(:centos, :name => "A")

      SystemImage.all.should == [a, z]
    end
  end
end
