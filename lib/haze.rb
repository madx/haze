require 'time'
require 'pathname'
require 'sinatra/base'
require 'haml'
require 'mime/types'

module Haze
  extend self

  attr_reader :posts, :drafts, :tags

  @posts, @drafts, @tags = [], {}

  def reload!
    @posts  = Dir['entries/*.hz'].map {|p|
      Post.open(p)
    }.sort_by {|p| p.date }

    @drafts = Dir['entries/*.draft'].map {|p|
      Post.open(p)
    }.sort_by {|p| p.date }

    @posts.map {|p| p.tags }.flatten.tap do |ts|
      @tags = ts.flatten.uniq.inject({}) {|h,t| h.merge({t => ts.count(t)}) }
    end
  end

  class Post
    attr_accessor :date, :slug, :title, :body, :tags

    def after
      Haze.posts[index+1]
    end

    def before
      index - 1 < 0 ? nil : Haze.posts[index-1]
    end

    def index
      Haze.posts.index(self) || -1
    end

    class << self
      def open(path)
        path = Pathname.new(path)
        new.tap {|p|
          get_attributes(path).map {|a,v| p.__send__(a, v) }
        }
      end

      private
      def get_attributes(path)
        Hash.new.tap do |a|
          header, body = path.read.split(/^---+$/, 2)
          date, a[:slug=] = path.basename.to_s.chomp(path.extname).split('_', 2)
          base, increment = date.split('+')
          a[:date=]  = Time.parse(base) + (increment || 0).to_i
          a[:title=] = header.gsub(/\{#.+\}/, '').gsub(/#(\w+)/, '\1').strip
          a[:tags=]  = header.scan(/#(\w+)/).flatten.map {|t| t.downcase }.uniq
          a[:body=]  = body.lstrip
        end
      end

      private :new
    end
  end

  class App < Sinatra::Base
    configure do
      set :haml, :attr_wrapper => '"'
    end

    get '/' do
      @entry = Haze.posts.last
      raise Sinatra::NotFound unless @entry

      haml :entry
    end
    # Fix to allow mapping to an url with Rack
    get('') { redirect env['SCRIPT_NAME']+'/' }

    get '/contents' do
      @entries = Haze.posts.reverse

      if params[:tag]
        @entries = @entries.select {|p| p.tags.include?(params[:tag]) }
      end

      haml :contents
    end

    get '/pub/*' do
      path = File.join('public', params[:splat].first)
      halt 403 if path.include?('..')

      content_type MIME::Types.of(path).first.to_s
      File.read path
    end

    get '/feed' do
    end

    get '/entry/:slug' do
      @entry = Haze.posts.detect {|p| p.slug == params[:slug] }
      raise Sinatra::NotFound unless @entry

      haml :entry
    end

    get '/draft/:slug' do
      @entry = Haze.drafts.detect {|p| p.slug == params[:slug] }
      raise Sinatra::NotFound unless @entry

      haml :entry
    end
  end
end
