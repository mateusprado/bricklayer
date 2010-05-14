require 'spec_helper'

describe 'Hash comparison method check_missing_keys' do
  def big_hash
    { "production_network"=>"Production", "graph_colors"=>["#FFAA00", "#1240AB", "#0000FF", "#FF0000"],
      "graph_color_pairs"=>[["#FFAA00", "#1240AB"], ["#00AAFF", "#AB4012"]], "vm_startup_time"=>180,
      "broker"=>{ :back_off_multiplier=>2, :max_reconnect_attempts=>0,
                  :initial_reconnect_delay=>5000, :randomize=>false, :backup=>false,
                  :timeout=>-1, :max_reconnect_delay=>10.0,
                  :hosts=>[ {:ssl=>true, :passcode=>"nephelae123", :port=>61612, :login=>"nephelae", :host=>"localhost"},
                            {:ssl=>false, :passcode=>"nephelae123", :port=>61613, :login=>"nephelae", :host=>"localhost"}],
                  :use_exponential_back_off=>false},
      "templates_path"=>"app/templates", "vm_ssh_wait_time"=>15,
      "server_registry"=>"http://10.11.0.15/seam/resource/ws", "scripts_path"=>"app/scripts",
      "error_recipients"=>["nobody@locaweb.com.br"],
      "opened_ports"=>[22, 21, 80, 3389],
      "graph_dimensions"=>{:height=>150, :width=>600}
     }
  end

  context 'when analysing hashes with the same keys, it should return an empty array' do
    it 'for an empty hash' do
      complete_hash = {}
      incomplete_hash = complete_hash.clone
      incomplete_hash.check_missing_keys(complete_hash).should be_empty
    end

    it 'for a single level hash' do
      complete_hash = {:a => 1, :b => 2}
      incomplete_hash = complete_hash.clone
      incomplete_hash.check_missing_keys(complete_hash).should be_empty
    end

    it 'for a double level hash' do
      complete_hash = {:a => 1, :b => {:b1 => 11, :b2 => 22, :b3 => 33}}
      incomplete_hash = complete_hash.clone
      incomplete_hash.check_missing_keys(complete_hash).should be_empty
    end

    it 'for a big, complex, multilevel level hash' do
      complete_hash = big_hash
      incomplete_hash = complete_hash.clone
      incomplete_hash.check_missing_keys(complete_hash).should be_empty
    end
  end

  context 'should return the missing keys' do
    it 'for a single level hash' do
      complete_hash = {:a => 1, :b => 2}
      incomplete_hash = {:a => 3}
      incomplete_hash.check_missing_keys(complete_hash).should == [:b]
    end

    it 'for a double level hash' do
      complete_hash = {:a => 1, :b => {:b1 => 11, :b2 => 22, :b3 => 33}}
      incomplete_hash = {:a => 3, :b => {:b2 => 22}}
      incomplete_hash.check_missing_keys(complete_hash).should == [{:b => [:b1, :b3]}]
    end

    context '- for a big, complex, multilevel level hash' do
      before :each do
        @complete_hash = big_hash
        @incomplete_hash = big_hash
      end

      it 'with one missing key on the first level' do
        @incomplete_hash.delete 'production_network'
        @incomplete_hash.check_missing_keys(@complete_hash).should == ['production_network']
      end

      it 'with two missing keys on the first level' do
        @incomplete_hash.delete 'production_network'
        @incomplete_hash.delete 'graph_colors'
        @incomplete_hash.check_missing_keys(@complete_hash).should == ['graph_colors', 'production_network']
      end

      it 'with one missing key on the first level and one on the second level' do
        @incomplete_hash.delete 'production_network'
        @incomplete_hash['broker'].delete :back_off_multiplier
        @incomplete_hash.check_missing_keys(@complete_hash).should == [{'broker' => [:back_off_multiplier]}, 'production_network']
      end
    end
  end
end
