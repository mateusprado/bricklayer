require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApplicationHelper do
  it "should be included in the object returned by #helper" do
    included_modules = (class << helper; self; end).send :included_modules
    included_modules.should include(ApplicationHelper)
  end

  context 'when returning the machine_status' do
    it 'should return installing if the machine status is either installing? or configuring?' do
      machine = VirtualMachine.new(:status => :machine_created)
      helper.machine_status(machine).should be(:installing)
    end
    it 'should return installed if the machine status is installed?' do
      machine = VirtualMachine.new(:status => :installed)
      helper.machine_status(machine).should be(:installed)
    end
    it 'should return error if the machine status is invalid_setup?' do
      machine = VirtualMachine.new(:status => :invalid_setup)
      helper.machine_status(machine).should be(:error)
    end
  end

  it 'should return all flash messages inside a p tag with class message and the flash name' do
    flash[:warning] = 'Testing Flash Warning'
    flash[:notice] = 'Testing Flash Notice'

    rendered_html = helper.flash_messages

    rendered_html.should have_tag 'p.message', 2
    rendered_html.should have_tag 'p.notice', 'Testing Flash Notice'
    rendered_html.should have_tag 'p.warning', 'Testing Flash Warning'
  end
  
end
