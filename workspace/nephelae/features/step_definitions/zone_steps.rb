Then /^I should see a new zone with name "([^\"]*)"$/ do |name|
  within ".zone" do |li|
    li.should contain(name)
  end
end

Then /^its ip adress should be "([^\"]*)"$/ do |ip|
  within ".zone" do |li|
    li.should contain(ip)
  end
end
