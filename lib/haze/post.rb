module Haze
  class Post
    attr_accessor :date, :slug, :title, :body, :tags

    def after
      Haze.posts[Haze.posts.index(self)+1]
    end

    def before
      (idx = Haze.posts.index(self) - 1) < 0 ? nil : Haze.posts[idx]
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
          date, a[:slug=] = path.basename.to_s.split('_', 2)
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
end
