require File.dirname(__FILE__) + "/spec_helper"
require "ostruct"

# unset models used for testing purposes
Object.unset_class('User', 'Thing')

class User < ActiveRecord::Base
  has_many :things
end

class Thing < ActiveRecord::Base
  belongs_to :user
end

class Helper
  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  
  attr_accessor :params, :request
  
  def params
    @params ||= {}
  end
  
  def request
    @request ||= OpenStruct.new
  end
end

describe "has_paginate" do
  before(:each) do
    @user = User.create(:name => "John")
    Array.new(31){|i| @user.things.create(:name => "Thing #{i}") }
  end
  
  describe "ActiveRecord" do
    it "should use default limit and offset, returning 11 records" do
      @user.things.paginate.should == Thing.all(:limit => 11)
    end
    
    it "should use other options" do
      @user.things.paginate(:order => 'id desc', :page => 1).should == Thing.all(:limit => 11, :order => 'id desc')
    end

    it "should use custom page" do
      @user.things.paginate(:page => 2).should == Thing.all(:limit => 11, :offset => 10)
    end

    it "should use custom limit" do
      @user.things.paginate(:page => 2, :limit => 5).should == Thing.all(:limit => 6, :offset => 5)
    end

    it "should paginate using class method" do
      Thing.paginate(:page => 4).should == Thing.all(:limit => 11, :offset => 30)
    end
    
    it "should paginate using class method with other options" do
      Thing.paginate(:page => 1, :order => 'id desc').should == Thing.all(:limit => 11, :order => 'id desc')
    end
  end
  
  describe "ApplicationHelper" do
    before(:each) do
      @helper = Helper.new
      @things = Thing.paginate
    end
    
    it "should use requested uri" do
      @helper.request.request_uri = "/requested/path"
      @helper.paginate(@things).should have_tag("a.next[href=/requested/path?page=2]", "Next page")
    end
    
    it "should remove existing param" do
      @helper.request.request_uri = "/requested/path?page=3"
      @helper.paginate(@things).should have_tag("a.next[href=/requested/path?page=2]", "Next page")
    end
    
    it "should use custom param name" do
      @helper.request.request_uri = "/requested/path?p=3"
      @helper.paginate(@things, :param_name => :p).should have_tag("a.next[href=/requested/path?p=2]", "Next page")
    end
    
    it "should call proc as url parameter" do
      @html = @helper.paginate(@things, :page => 2, :url => proc {|page| "/some/path/#{page}" })
      @html.should have_tag("a.next[href=/some/path/3]", "Next page")
      @html.should have_tag("a.previous[href=/some/path/1]", "Previous page")
    end
    
    it "should have current page number" do
      @helper.paginate(@things, '/some/path').should have_tag("ul.paginate") do |ul|
        ul.should have_tag("li.page.page-1") do |li|
          li.should have_tag("span", "Page 1")
        end
      end
    end
    
    it "should not have current page number" do
      @helper.paginate(@things, '/some/path', :show_page => false).should have_tag("ul.paginate") do |ul|
        ul.should_not have_tag("li.page")
      end
    end
    
    it "should iterate elements with each_paginate discarding the last record" do
      names = []
      indexes = []
      
      @helper.each_paginate(@things) do |thing, i| 
        names << thing
        indexes << i
      end
      
      names.should == @things[0...10]
      indexes.should == (0..9).to_a
    end
    
    it "should have next page" do
      @helper.paginate(@things, '/some/path').should have_tag("ul.paginate") do |ul|
        ul.should have_tag("li.next") do |li|
          li.should have_tag("a.next[href=/some/path?page=2]", "Next page")
        end
      end
    end
    
    it "should have previous page" do
      @helper.paginate(@things, '/some/path', :page => 3).should have_tag("ul.paginate") do |ul|
        ul.should have_tag("li.previous") do |li|
          li.should have_tag("a.previous[href=/some/path?page=2]", "Previous page")
        end
      end
    end
    
    it "should not have previous page" do
      @helper.paginate(@things, '/some/path', :show_disabled => false).should have_tag("ul.paginate") do |ul|
        ul.should_not have_tag("li.previous") 
      end
    end
    
    it "should not have next page" do
      @helper.paginate(@things[0...5], '/some/path', :page => 5, :show_disabled => false).should have_tag("ul.paginate") do |ul|
        ul.should_not have_tag("li.next") 
      end
    end
    
    it "should have disabled previous page" do
      @helper.paginate(@things, '/some/path').should have_tag("ul.paginate") do |ul|
        ul.should have_tag("li.previous.disabled") do |li|
          li.should have_tag("span", "Previous page")
        end
      end
    end
    
    it "should have disabled next page" do
      @helper.paginate(@things[0...5], '/some/path', :page => 5).should have_tag("ul.paginate") do |ul|
        ul.should have_tag("li.next.disabled") do |li|
          li.should have_tag("span", "Next page")
        end
      end
    end
    
    it "should use custom next page label" do
      @helper.paginate(@things, '/some/path', :next_label => "Recent").should have_tag("a.next", "Recent")
    end
    
    it "should use custom previous page label" do
      @helper.paginate(@things, '/some/path', :page => 2, :previous_label => "Older").should have_tag("a.previous", "Older")
    end
    
    it "should use custom param name" do
      @helper.paginate(@things, '/some/path', :param_name => :p).should have_tag("a.next[href=/some/path?p=2]")
    end
    
    it "should use custom page format" do
      @helper.paginate(@things, '/some/path', :format => 'Página %d').should have_tag("li.page", 'Página 1')
    end
  end
  
  describe "settings" do
    before(:each) do
      @settings = {
        :next_label => 'Next page',
        :previous_label => 'Previous page',
        :param_name => :page,
        :show_disabled => true,
        :show_page => true, 
        :limit => 10,
        :format => 'Page %d'
      }
    end
    
    it "should have default settings" do
      Paginate.settings.should == @settings
    end
    
    it "should override default settings" do
      Paginate.settings = {:show_page => false}
      Paginate.settings.should == @settings.merge(:show_page => false)
    end
  end
  
  describe "ActiveRecord extension" do
    it "should insert class method" do
      doing { User.find_in_chunks {|u| u.id } }.should_not raise_error
    end
    
    it "should insert association method" do
      doing { @user.things.find_in_chunks {|t| t.id } }.should_not raise_error
    end
    
    it "should have items? method" do
      @user.things.paginate.items?.should be_true
      Thing.paginate.items?.should be_true
    end
    
    it "should not repeat items" do
      items = []
      @user.things.find_in_chunks {|t| items << t.id }
      items.size.should == @user.things.count
    end
  end
end