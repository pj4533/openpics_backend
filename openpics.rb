require 'bundler/setup'
Bundler.require(:default)

require 'rubygems'
require 'sinatra'
require 'json'
require 'yaml'
require 'haml'

# enable :inline_templates
set :root, File.dirname(__FILE__)

get '/' do
	haml :index, :locals => {}
end

