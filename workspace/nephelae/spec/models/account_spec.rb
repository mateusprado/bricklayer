require File.dirname(__FILE__) + '/../spec_helper'

describe Account do
  should_validate_presence_of :login
  should_have_many :virtual_machines, :dependent => :destroy

  context 'should return' do
    before :all do
      @system_image = Factory(:centos)
    end

    after :all do
      @system_image.destroy
    end

    before :each do
      subject.login = 'test'
      subject.save
      VirtualMachine.without_callbacks do
        Factory(:uninstalled_vm, :system_image => @system_image, :account => subject, :memory => 1024, :hdd => 15, :cpus => 1)
        Factory(:installed_vm, :system_image => @system_image, :account => subject, :memory => 2048, :hdd => 40, :cpus => 2)
        Factory(:installed_vm  , :system_image => @system_image, :account => subject, :memory => 2048, :hdd => 40, :cpus => 2)
      end
      subject.virtual_machines.count.should be(3)
    end

    it 'the count of activated machines' do
      subject.current_machine_count.should be(2)
    end

    context 'the sum of all activated machines' do
      it 'memory' do
        subject.current_allocated_memory.should be(4096)
      end

      it 'hdd' do
        subject.current_allocated_hdd.should be(80)
      end

      it 'cpus' do
        subject.current_allocated_cpus.should be(4)
      end
    end
  end
  
  it "should return the user name based on CAS login" do
    subject.login = "domain/user"
    subject.user.should be("user")
  end
  
  it "should return the login as user name if non CAS based login" do
    subject.login = "testuser"
    subject.user.should be("testuser")
  end

  context 'when checking if a machine that is not within the account limits' do
    before :each do
      @vm = Factory.build(:awaiting_validation_vm, :memory => 99999999, :hdd => 99999999, :cpus => 99999999)
      subject.stub!(:maximum_machine_count).and_return(0)
      subject.within_limits?(@vm)
    end

    it 'should return false' do
      subject.within_limits?(@vm).should be_false
    end

    it 'should add exceeded_maximum_machines error to the base object' do
      @vm.should include_error_message_for(:base, :exceeded_maximum_machines, :count => subject.maximum_machine_count)
    end

    it 'should add exceeded_maximum_machines error to the memory attribute' do
      @vm.should include_error_message_for(:memory, :exceeded_maximum_memory, :limit => subject.maximum_memory)
    end

    it 'should add exceeded_maximum_machines error to the hdd attribute' do
      @vm.should include_error_message_for(:hdd, :exceeded_maximum_hdd, :limit => subject.maximum_hdd)
    end

    it 'should add exceeded_maximum_machines error to the cpus attribute' do
      @vm.should include_error_message_for(:cpus, :exceeded_maximum_cpus, :limit => subject.maximum_cpus)
    end
  end

  context 'when instantiating a new account' do
    it 'should have a default maximum_machine_count of 1' do
      subject.maximum_machine_count.should be(1)
    end
    
    it 'should have a default maximum_memory of 4096 MB' do
      subject.maximum_memory.should be(4096)
    end
    
    it 'should have a default maximum_hdd of 80 GB' do
      subject.maximum_hdd.should be(80)
    end
    
    it 'should have a default maximum_cpus of 4 cpus' do
      subject.maximum_cpus.should be(4)
    end
  end

  it "should return all the zones used by it's machines" do
    subject.login = 'me'
    subject.maximum_machine_count = 10
    subject.maximum_hdd = 10000
    subject.maximum_memory = 10000
    subject.save

    system_image = Factory(:centos)

    first_zone = Factory(:zone, :name => 'first_zone')
    second_zone = Factory(:zone, :name => 'second_zone')
    other_zone = Factory(:zone, :name => 'other_zone')

    other_account = Factory(:test_account)

    first_machine = Factory(:installed_vm, :system_image => system_image, :zone => first_zone, :account => subject)
    second_machine = Factory(:installed_vm, :system_image => system_image, :zone => second_zone, :account => subject)
    other_machine = Factory(:installed_vm, :system_image => system_image, :zone => other_zone, :account => other_account)

    subject.zones.to_set.should == Set.new([first_zone, second_zone])
  end

  context 'when choosing an available zone for a machine' do
    it "should search the zones already used by other account's machines" do
      @zone = Factory(:zone)
      @vm = Factory(:installed_vm, :zone => @zone, :account => subject)
      @zone.stub!(:can_accomodate_machine?).and_return(true)
      subject.should_receive(:zones).and_return([@zone])
      
      new_vm = VirtualMachine.new(:account => subject)
      subject.choose_zone_for(new_vm).should == @zone
    end

    it "should search all zones if no zone used by the account is available" do
      zone = Factory(:zone)
      zone.stub!(:can_accomodate_machine?).and_return(false)
      other_zone = Factory(:zone, :name => 'other_zone')
      other_zone.stub!(:can_accomodate_machine?).and_return(true)
      
      subject.should_receive(:zones).and_return([zone])
      Zone.should_receive(:all).and_return([zone, other_zone])
      
      subject.maximum_memory = 10240
      Factory(:installed_vm, :zone => zone, :account => subject, :memory => 10240)
      subject.choose_zone_for(VirtualMachine.new(:memory => 1024)).should == other_zone
    end

    it 'should return nil if there is no suitable zone' do
      subject.choose_zone_for(VirtualMachine.new(:memory => 1024)).should be_nil
    end
  end
end
