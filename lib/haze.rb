require 'time'
require 'pathname'
require 'sinatra/base'
require 'mime/types'
require 'haml'
require 'builder'
require 'sequel'

module Haze
  extend self

  DB = Sequel.connect 'sqlite://comments.db'

  DB.create_table? :comments do
    primary_key :id
    String      :entry
    String      :author
    String      :email
    String      :website
    Text        :body
    Time        :date
  end

  attr_reader :entries, :drafts, :tags, :options, :static

  @entries, @drafts, @static, @tags, @options = [], [], [], {}, {}

  def set(opt, value=true)
    options[opt] = value
  end

  def opt(opt)
    options[opt]
  end

  set :title,  "My blog"
  set :author, "My name"
  set :domain, "http://example.com/"
  set :email,  "me@example.com"
  set :key,    "80aa59ada7f50f58c8cf4f43410f3c40c4e15149"
  set :menu,   {
    "Home"     => ["Home", "/"],
    "Archives" => ["View archives", "/archive"]
  }

  def reload!
    @entries = Dir['entries/*.hz'].map {|p|
      Entry.open(p)
    }.sort_by {|e| e.date }

    @drafts = Dir['entries/*.draft'].map {|p|
      Entry.open(p)
    }.sort_by {|e| e.date }

    @entries.map {|e| e.tags }.flatten.tap do |ts|
      @tags = ts.flatten.uniq.inject({}) {|h,t| h.merge({t => ts.count(t)}) }
    end
  end


  class Entry
    attr_accessor :date, :slug, :title, :body, :tags

    def after
      Haze.entries[index+1]
    end

    def before
      index - 1 < 0 ? nil : Haze.entries[index-1]
    end

    def index
      Haze.entries.index(self) || -1
    end

    def url
      File.join(Haze.opt(:domain), 'entry', slug)
    end

    def comments
      Comment.filter(:entry => slug).order(:date)
    end

    class << self
      def open(path)
        path = Pathname.new(path)
        new.tap {|e|
          get_attributes(path).map {|a,v| e.__send__(a, v) }
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


  class Comment < Sequel::Model
    def self.create(params)
      data = params.reject {|k,v|
        !%w(author email website body).member?(k)
      }.update(:entry => params[:slug], :date => Time.now)

      %w(author email website body).each {|k|
        data[k] = Rack::Utils.escape_html(data[k])
      }

      super(data)
    end
  end


  class App < Sinatra::Base
    configure do
      set :haml, :attr_wrapper => '"'
    end

    helpers do
      def make_title
        if @entry
          [@entry.title, Haze.opt(:title)].join(Haze.opt(:titlesep) || " | ")
        else
          Haze.opt :title
        end
      end

      def partial(page, options={})
        haml "_#{page}".to_sym, options.merge!(:layout => false)
      end
    end

    get '/' do
      @entry = Haze.entries.last
      raise Sinatra::NotFound unless @entry

      haml :entry
    end
    # Fix to allow mapping to an url with Rack
    get('') { redirect env['SCRIPT_NAME']+'/' }

    get '/archive' do
      @entries = Haze.entries.reverse

      if params[:tag]
        @entries = @entries.select {|p| p.tags.include?(params[:tag]) }
      end

      haml :archive
    end

    get '/pub/*' do
      path = File.join('public', params[:splat].first)
      halt 403 if path.include?('..')
      raise Sinatra::NotFound unless File.exist?(path)

      content_type MIME::Types.of(path).first.to_s
      File.read path
    end

    get '/feed' do
      content_type 'application/atom+xml'
      @entries = Haze.entries.last(20).reverse

      builder :feed
    end

    get '/_sync_' do
      if params[:key] == Haze.opt(:key)
        Haze.reload!
        "done"
      else
        halt 403, "bad key."
      end
    end

    get '/entry/:slug' do
      @entry = Haze.entries.detect {|p| p.slug == params[:slug] }
      raise Sinatra::NotFound unless @entry

      haml :entry
    end

    post '/entry/:slug' do
      @entry = Haze.entries.detect {|p| p.slug == params[:slug] }
      raise Sinatra::NotFound unless @entry
      halt 403 unless params[:rcaptcha].empty?

      [:author, :body].each {|f| halt 500 if params[f].empty? }

      Comment.create(params)

      redirect request.url + '#comments'
    end

    get '/draft/:slug' do
      @entry = Haze.drafts.detect {|p| p.slug == params[:slug] }
      raise Sinatra::NotFound unless @entry

      haml :draft
    end

    get '/static/:page' do
      path = File.join('static', params[:page])
      halt 403 if path.include?('..')
      raise Sinatra::NotFound unless File.exist?(path)

      @contents = File.read(path)

      haml :static
    end

    error Sinatra::NotFound do
      haml :not_found
    end
  end
end
