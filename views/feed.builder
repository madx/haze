xml.instruct! :xml, :version => "1.0"
xml.feed :xmlns => "http://www.w3.org/2005/Atom" do
  xml.id Haze.opt(:uri)
  xml.title Haze.opt(:title)
  xml.updated @entries.first.date.xmlschema
  xml.link :href => Haze.opt(:uri)
  xml.link :rel => "self", :href => File.join(Haze.opt(:uri), 'feed')
  xml.author do
    xml.name  Haze.opt(:author)
    xml.email Haze.opt(:email)
    xml.uri   Haze.opt(:uri)
  end

  @entries.each do |entry|
    xml.entry do
      xml.id entry.url
      xml.title entry.title, :type => "html"
      xml.updated entry.date.xmlschema
      xml.author do
        xml.name  Haze.opt(:author)
        xml.email Haze.opt(:email)
        xml.uri   Haze.opt(:uri)
      end
      xml.link :rel => "alternate", :href => entry.url
      xml.summary :type => "xhtml" do
        xml.div :xmlns => "http://www.w3.org/1999/xhtml" do
          xml << entry.body
        end
      end
      entry.tags.each do |tag|
        xml.category :term => tag,
                     :scheme => File.join(Haze.opt(:uri), "archive?tag=#{tag}")
      end
    end
  end
end
