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

	query_clause = ""
	if query
		query_clause = "WHERE image_title ILIKE '%#{query}%'"
	end

	offset = page.to_i * limit.to_i
	total_images = get_total_images(query_clause)
	total_pages = (total_images / limit.to_i).ceil

	db = URI.parse(ENV["DATABASE_URL"])
	c = PG.connect(
		:host => db.host, 
		:port => db.port,
		:user => db.user,
		:password => db.password,
		:dbname => db.path[1..-1] )
	images = []

	result = c.exec( "SELECT * FROM images #{query_clause} ORDER BY date DESC LIMIT #{limit} OFFSET #{offset}" )
	
	result.each do |row|
		image_provider_specific = nil
		if row['image_provider_specific'] != "null"
			image_provider_specific = JSON.parse(row['image_provider_specific'])		
		end
		images << {
			"date" => row['date'],
			"id" => row['image_id'],
			"imageUrl" => row['image_url'],
			"title" => row['image_title'],
			"providerSpecific" => image_provider_specific,
			"providerType" => row['image_provider_type'],
			"width" => row['image_width'],
			"height" => row['image_height']
		}
	end

	c.close	

	content_type 'application/json'
	full_envelope = {"data" => images}
	paging = {"page" => page, "limit" => limit, "total_pages" => total_pages.to_s, "total_count" => total_images.to_s }
	full_envelope["paging"] = paging
	full_envelope.to_json

end