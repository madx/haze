module Haze
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
  end
end
