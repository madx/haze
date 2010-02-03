require File.join(File.dirname(__FILE__), '..', 'lib', 'haze')

# Override Pathname#read for these tests so it returns fake contents
class Pathname
  def read
<<EOF
{#post} Hello #World {#greeting,#post}
---
This is my first post !
EOF
  end
end

describe Haze::Entry do
  it "has it's .new method disabled" do
    lambda { Haze::Entry.new }.should.raise(NoMethodError)
  end

  it "is opened by .open" do
    entry = Haze::Entry.open('2010-01-01_Hello.hz')
    entry.should.be.kind_of Haze::Entry
  end

  describe ".open" do
    before do
      @entry = Haze::Entry.open('2010-01-01_Hello.hz')
    end

    it "extracts tags from the header, removing duplicates " +
       "and lowercasing them" do
      @entry.tags.should == %w(post world greeting)
    end

    it "extracts the body" do
      @entry.body.should =~ /^This is my first post !/
    end

    it "extract the slug from the filename" do
      @entry.slug.should == "Hello"
    end

    it "extracts the date from the filename" do
      @entry.date.should == Time.parse("2010-01-01")
    end

    it "adds increments to the date if there's a + after it" do
      other = Haze::Entry.open('2010-01-01+1_slug.hz')
      @entry.date.should.not.be == other.date
    end
  end

  describe "#url" do
    it "returns a friendly url for the entry" do
      entry = Haze::Entry.open('2010-01-01_Hello.hz')
      entry.url.should == File.join(Haze.opt(:domain), 'entry', 'Hello')
    end
  end

end
