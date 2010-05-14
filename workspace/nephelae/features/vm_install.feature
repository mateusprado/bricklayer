@notxn
Feature: VirtualMachine install
  In order to verify the complete installation
  As an administrator
  I want to issue an install
    
  @installation
  Scenario: New VirtualMachine install
    Given an existent account
    And an existent zone
    And an existent vlan
    And an existent master
    And an existent public_ip range
    And an existent DHCP server
    And an existent Firewall
    And an existent VncProxy
    And an existent "debian" matrix with uuid "75f07750-3f5b-25f8-8384-7fd844646d48"
	  And a virtual machine

  	When I set password as "$P4ssw0rd^"
  	And I save

    Then it should change state to "installed" after 10 minutes
    And it should have valid public and private ip address
    And it should be accessible using ssh with user and password
    And it should not be accessible using ssh with keys 
    And the security sensitive files should be deleted
    And it should be in production network
    And it should be able to access internet
    And it should have the defined hardware
