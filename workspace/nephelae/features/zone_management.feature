Feature: Zone management
  In order to control healthy of servers
  As a administrator
  I want to monitor hosts and ssh keys

  
Scenario: New Zone Registration
  Given I am on admin_zone registration form
  When I fill in "zone_name" with "Matrix_Homologacao"
  And I fill in "zone_number" with "123"
  And I fill in "zone_master_attributes_name" with "XEN05"
  And I fill in "zone_master_attributes_ip" with "10.9.19.220"
  And I fill in "zone_master_attributes_username" with "root"
  And I fill in "zone_master_attributes_password" with "locadmin123!@#"
  And I press "insert"
  Then I should be on zones page
  And I should not see "Não foi possível gravar zone"
  And I should see a new zone with name "Matrix_Homologacao"
  And its ip adress should be "10.9.19.220"
