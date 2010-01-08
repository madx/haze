Haze
====

Haze is a minimalistic blogging engine, in the spirit of
[Honk](http://github.com/madx/honk), it's predecessor.

It has very few features compared to other blog engines. Exhaustively:

* Entries, stored in flat text files
* Tags
* An archive page that lists every entry
* An Atom feed

Why so few? Well, I simply don't need more.

Haze's source code is very short (~150LOC) thus the app is light and quick.

## Requirements ##############################################################

* sinatra (tested with 0.9.4)

## Install ###################################################################

    $ git clone git://github.com/madx/haze.git

Copy the files where you want to install it, then edit `config.ru` if you
want to change the defaults. Use plain ruby to do the configuration, like
this:

    require File.join(File.dirname(__FILE__), 'lib', 'haze')

    Haze.tap do |config|
      config.set :title,  "Blog title"
      config.set :author, "Your name"
      config.set :uri,    "http://example.com/"
    end

    Haze.reload!

    run Haze::App

Create the folder where you will put your entries: `mkdir entries`.
Then run the app with `$ rackup -E production config.ru`.

## Source ####################################################################

Haze's Git repo is available on GitHub, which can be browsed at
<http://github.com/madx/haze> and cloned with:

    git clone git://github.com/madx/haze.git

## Usage #####################################################################

Haze entry format enforces a few conventions:

An entry is split in two parts. The first is a header and the second the entry
body. The separator is a succession of at least three `-` put on a line of their
own.

The header will be the title of your entry. Every word starting with a `#` will
create a new tag. Tags are automatically lowercase'd. You can add tags that
won't show up in the title by enclosing them in braces (`{}`).

To determine the order of entries and their URLs, you have to give a correct
name to the file they are stored into.

The format is: `<date>[+<counter>]_<slug>.(hz/draft)`.

`<date>` must be parseable by `Time.parse`, the handiest format to use is
probably `<year>-<month>-<day>`. The `+<counter>` part allows you to write
multiple entries with on single `<date>`. Behind the scenes, it simply adds
`<counter>` seconds to the parsed date.

`<slug>` will be the name of the URL for your entry. `hz` or `draft` tells if
the file is a regular entry or a draft.

Drafts are viewable using the url `/draft/<slug>`.

Example:

    $ cat entries/2009-01-08_ruby_hello_world.hz
    A #Ruby Hello world program {#tutorial,#programming}
    ---
    <p>Hello world is the most common program used to demonstrate a language's
    syntax. Here is one in Ruby: </p>

    <pre><code>puts "hello world"</code></pre>

* Title: A Ruby Hello world program
* Tags: ruby, tutorial, programming
* Date: 2009-01-08
* Slug: ruby_hello_world

