Haze
====

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

Then run the app with $ rackup -E production config.ru

## Source ####################################################################

Haze's Git repo is available on GitHub, which can be browsed at
<http://github.com/madx/haze> and cloned with:

    git clone git://github.com/madx/haze.git

## Usage #####################################################################


## Formatting ################################################################


## Contributors ##############################################################
