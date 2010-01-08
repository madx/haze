require 'time'
require 'pathname'
require 'sinatra/base'
require 'haml'
require 'mime/types'

module Haze
  extend self

  attr_reader :posts, :tags

  @posts, @tags = [], {}

  def reload!
    @posts = Dir['entries/*'].map {|p| Post.open(p) }.sort_by {|p| p.date }
    @posts.map {|p| p.tags }.flatten.tap do |ts|
      @tags = ts.flatten.uniq.inject({}) {|h,t| h.merge({t => ts.count(t)}) }
    end
  end

end

%w(post app).each {|l|
  require File.join(File.dirname(__FILE__), 'haze', l)
}
