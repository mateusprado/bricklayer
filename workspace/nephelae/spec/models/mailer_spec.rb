require File.dirname(__FILE__) + "/../spec_helper"

describe Mailer do

  it "should send email about error on any active record object" do
    zone = Factory(:zone)
    ActionMailer::Base.deliveries = []
    mail = Mailer.deliver_error_email(zone, RuntimeError.new("Test message"))  
    ActionMailer::Base.deliveries.size.should be(1)
    mail.body.should include("Type: RuntimeError")
    mail.body.should include("Message: Test message")
    mail.body.should include("Subject: Zone.#{zone.id}")
  end

end
