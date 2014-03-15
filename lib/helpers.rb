require 'json'
require 'rubygems'

def get_total_images
	db = URI.parse(ENV["DATABASE_URL"])
	c = PG.connect(
		:host => db.host, 
		:port => db.port,
		:user => db.user,
		:password => db.password,
		:dbname => db.path[1..-1] )
	result = c.exec( "SELECT COUNT(*) FROM images" )
	total_image_count = result[0]['count'].to_i
	c.close

	total_image_count
end
