require File.dirname(__FILE__) + "/../spec_helper"

describe RailsLogging do
  
  class ClassWithLogging
    include RailsLogging
  end
  
  subject { ClassWithLogging.new }
  
  it "should make the Rails logger accessible" do
    subject.should respond_to(:logger)
    subject.logger.should be(Rails.logger)
  end
  
  it "should include the logger accessor in the Class object too" do
    ClassWithLogging.should respond_to(:logger)
    ClassWithLogging.logger.should be(Rails.logger)
  end
  
end
