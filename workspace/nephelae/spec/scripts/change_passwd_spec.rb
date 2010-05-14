require File.dirname(__FILE__) + '/../spec_helper'

describe "change_passwd script" do
  before :each do
    # TODO: See if it's possible to fix the scripts_folder so we don't need to stub it here
    SSHExecutor.stub!(:scripts_folder).and_return("#{File.expand_path(Rails.root)}/app/scripts")
  end

  it 'should generate the right commands to create the shadow password' do
    script = prepare_and_render_script 'change_passwd',
                                       :passwd_hash => 'abc-password-hash'
    script.should == '#!/bin/bash
# Script para mudar o root password
#
shadow_hash="abc-password-hash"
sed -i "s/^root:[^:]\+:\(.\+\)$/root:${shadow_hash}:\1/" /etc/shadow
'
  end

end
