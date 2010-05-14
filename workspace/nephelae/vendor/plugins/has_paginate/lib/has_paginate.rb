class Paginate
  @@settings = {
    :next_label => "Next page",
    :previous_label => "Previous page",
    :param_name => :page,
    :show_disabled => true,
    :show_page => true, 
    :limit => 10,
    :format => "Page %d"
  }
  
  def self.settings=(options)
    @@settings.merge!(options)
  end
  
  def self.settings
    @@settings
  end
  
  def self.limit(options)
    options[:limit] ||= settings[:limit]
    (options[:limit].to_i == 0 ? 10 : options[:limit].to_i)
  end
  
  def self.offset(options={})
    (page(options) - 1) * limit(options)
  end
  
  def self.page(options={})
    [options[:page].to_i, 1].max
  end
  
  def self.options(*args)
    options = args.first
    
    unless options.kind_of?(Hash)
      options = {:page => options}
    end
    
    options.except(:page).merge(:offset => offset(options), :limit => limit(options))
  end
end

module FindInChunksExtension
  def find_in_chunks(options={}, &block)
    page = 1
    
    while true
      # force all method
      records = paginate(options.merge(:page => page)).all
      
      # do get sizes
      size = records.size
      limit = Paginate.limit(options)
      
      page += 1
      
      # if size is greater than limit, remove last record
      records.pop if size > limit
      
      records.each(&block)
      
      # break if limit is greater than size
      break if size <= limit
    end
  end
end

module ActiveRecord
  class Base
    # Post.paginate                             #=> page #1 with size 10
    # Post.paginate(1)                          #=> page #1 with size 10
    # Post.paginate(:page => 1, :limit => 30)   #=> page #1 with size 30
    # Post.paginate(params[:page])
    # Post.paginate(params[:page].to_i)
    # Post.first.comments.paginate
    named_scope :paginate, Proc.new{ |*args|
      options = Paginate.options(*args)
      options[:limit] += 1
      options 
    }
  end
end

class ActiveRecord::NamedScope::Scope
  def items?
    !self.length.zero?
  end
end

module ApplicationHelper
  # <%= paginate @posts %>
  # <%= paginate @posts, options %>
  # <%= paginate @posts, posts_path, options %>
  def paginate(collection, *args)
    if args[0].kind_of?(Hash)
      options = args[0] || {}
    else
      options = args[1] || {}
      options[:url] = args[0]
    end
    
    options = Paginate.settings.merge(options)
    
    options.merge!(Paginate.options(options))
    options[:page] ||= params[options[:param_name]]
    
    url = options.delete(:url)
    
    unless url.kind_of?(Proc)
      url ||= request.request_uri
    
      re = Regexp.new("([&?])#{Regexp.escape(options[:param_name].to_s)}=[0-9]+")
      url.gsub!(re, "\\1")
      url.gsub!(/\?$/, "")
      url.gsub!(/\?&/, "?")
      url = URI.parse(url).to_s
      
      connector = (url =~ /\?/) ? "&amp;" : "?"
    end
    
    current_page = Paginate.page(options)
    
    returning "" do |contents|
      previous_item = ""
      next_item = ""
      page = ""
      
      if current_page > 1
        if url.kind_of?(Proc)
          previous_url = url.call(current_page - 1)
        else
          previous_url = url
          previous_url += connector + (current_page - 1).to_s.to_query(options[:param_name]) if current_page > 2
        end
        
        link = content_tag(:a, options[:previous_label], :class => "previous", :href => previous_url)
        previous_item << content_tag(:li, link, :class => "previous")
      elsif options[:show_disabled]
        previous_item << content_tag(:li, content_tag(:span, options[:previous_label]), :class => "previous disabled")
      end
      
      if collection.length > Paginate.limit(options)
        if url.kind_of?(Proc)
          next_url = url.call(current_page + 1)
        else
          next_url = url + connector + (current_page + 1).to_s.to_query(options[:param_name])
        end
        
        link = content_tag(:a, options[:next_label], :class => "next", :href => next_url)
        next_item << content_tag(:li, link, :class => "next")
      elsif options[:show_disabled]
        next_item << content_tag(:li, content_tag(:span, options[:next_label]), :class => "next disabled")
      end
      
      if options[:show_page]
        page << content_tag(:li, content_tag(:span, options[:format] % current_page), :class => "page page-#{current_page}")
      end
      
      if options[:disabled] || !previous_item.blank? || !next_item.blank?
        contents << content_tag(:ul, previous_item + page + next_item, :class => "paginate")
      end
    end
  end
  
  # <% each_paginate @posts do |item, i| %>
  # <% each_paginate @posts, :limit => 12 do |item, i| %>
  def each_paginate(collection, options={}, &block)
    # get options
    options[:page] = params[Paginate.settings[:param_name]] unless options.key?(:page)
    options.merge!(Paginate.options(options))

    # iterate
    collection[0...options[:limit]].each_with_index do |item, i|
      yield item, i
    end
  end
end