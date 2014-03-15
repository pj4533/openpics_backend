require './openpics.rb'
require 'haml'

run Rack::URLMap.new \
  "/"       => Sinatra::Application
