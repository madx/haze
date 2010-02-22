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
    @entries = read_entries('entries/*.hz')
    @drafts  = read_entries('entries/*.draft')

    @entries.map {|e| e.tags }.flatten.tap do |ts|
      @tags = ts.flatten.uniq.inject({}) {|h,t| h.merge({t => ts.count(t)}) }
    end
  end

  private

  def read_entries(mask)
    Dir[mask].map {|p|
      Entry.open(p)
    }.sort_by {|e| e.date }
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
          sep = Haze.opt(:titlesep) || ' | '
          [@entry.title.gsub(/<\/?[^>]+>/, ''), Haze.opt(:title)].join(sep)
        else
          Haze.opt :title
        end
      end

      def partial(page, options={})
        haml "_#{page}".to_sym, options.merge!(:layout => false)
      end

      def fetch_entry_in(collection)
        collection.detect {|p| p.slug == params[:slug] }.tap do |e|
          not_found unless e
        end
      end

      def try_path(path)
        halt 403, "forbidden" if path.include?('..')
        not_found unless File.exist?(path)
        return path
      end
    end

    get '/' do
      @entry = Haze.entries.last
      not_found unless @entry

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
      path = try_path(File.join('public', params[:splat].first))

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

    get '/stylesheet.css' do
      content_type 'text/css'
      File.read 'stylesheet.css'
    end

    get '/entry/:slug' do
      @entry = fetch_entry_in Haze.entries

      haml :entry
    end

    get '/draft/:slug' do
      @entry = fetch_entry_in Haze.drafts

      haml :draft
    end

    get '/static/:page' do
      path = try_path(File.join('static', params[:page]))
      @contents = File.read(path)

      haml :static
    end

    post '/entry/:slug' do
      @entry = fetch_entry_in Haze.entries
      halt 403, "looks like spam" unless params[:rcaptcha].empty?

      [:author, :body].each {|f|
        halt 500, "invalid form data" if params[f].empty?
      }

      Comment.create(params)

      redirect request.url + '#comments'
    end

    error 404 do
      haml :not_found
    end
  end
end
