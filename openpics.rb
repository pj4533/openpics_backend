require 'bundler/setup'
Bundler.require(:default)

require 'rubygems'
require 'sinatra'
require 'json'
require 'yaml'
require 'haml'
require 'pg'
require './lib/helpers'
require 'statsmix'

# enable :inline_templates
set :root, File.dirname(__FILE__)

get '/' do
	haml :index, :locals => {}
end

post '/images' do
	image_json = JSON.parse(request.body.read)

	StatsMix.track('Images Favorited', 1, {:meta => {'provider type' => image_json['providerType']}})

	db = URI.parse(ENV["DATABASE_URL"])
	c = PG.connect(
		:host => db.host, 
		:port => db.port,
		:user => db.user,
		:password => db.password,
		:dbname => db.path[1..-1] )
	result = c.exec( "SELECT * FROM images WHERE image_url = \'#{image_json['imageUrl']}\'" )
	if result.count > 0
		image = result[0]
		query = "UPDATE images SET date = DEFAULT WHERE image_id = #{image['image_id']}"
	else
		query = get_insert_query_from_image(c,image_json)
	end
	c.exec(query)

	content_type 'application/json'
	'{}'
end

get '/images' do
	StatsMix.track("Pages Returned")

	page = params[:page]
	query = params[:query]
	limit = params[:limit]

	if !page
		page = 0
	end
	if !limit
		limit = 50
	end

	content_type 'application/json'
	get_images(query,limit,page,true).to_json

end

get '/image/hide/:image_id' do
	db = URI.parse(ENV["DATABASE_URL"])
	c = PG.connect(
		:host => db.host, 
		:port => db.port,
		:user => db.user,
		:password => db.password,
		:dbname => db.path[1..-1] )
	c.exec("UPDATE images SET is_hidden = TRUE WHERE image_id = #{params[:image_id]}")

	redirect  URI::encode '/'
end

get '/image/unhide/:image_id' do
	db = URI.parse(ENV["DATABASE_URL"])
	c = PG.connect(
		:host => db.host, 
		:port => db.port,
		:user => db.user,
		:password => db.password,
		:dbname => db.path[1..-1] )
	c.exec("UPDATE images SET is_hidden = FALSE WHERE image_id = #{params[:image_id]}")

	redirect  URI::encode '/'
end
