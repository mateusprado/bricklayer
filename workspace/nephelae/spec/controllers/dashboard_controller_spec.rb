require 'spec_helper'

describe DashboardController do
  it "should be routed as root" do
    {:get => "/"}.should route_to(:controller => "dashboard", :action => "index")
  end
end
