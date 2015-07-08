require 'json'
require 'rubygems'

def get_images(query,limit,page,exclude_hidden)

	query_clause = ""
	if query
		query_clause = "WHERE image_title ILIKE '%#{query}%'"
		if exclude_hidden
			query_clause = "#{query_clause} AND NOT is_hidden"
		end
	elsif exclude_hidden
		query_clause = "WHERE NOT is_hidden"
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
# change this to just approved provider types, not excluding specific ones
		if row['image_provider_type'] != "com.saygoodnight.redditporn"
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
				"height" => row['image_height'],
				"hidden" => row['is_hidden']
			}		
		end
	end

	c.close	

	full_envelope = {"data" => images}
	paging = {"page" => page, "limit" => limit, "total_pages" => total_pages.to_s, "total_count" => total_images.to_s }
	full_envelope["paging"] = paging

	full_envelope
end

def get_total_images(query_clause)
	db = URI.parse(ENV["DATABASE_URL"])
	c = PG.connect(
		:host => db.host, 
		:port => db.port,
		:user => db.user,
		:password => db.password,
		:dbname => db.path[1..-1] )
	result = c.exec( "SELECT COUNT(*) FROM images #{query_clause}" )
	total_image_count = result[0]['count'].to_i
	c.close

	total_image_count
end

def get_insert_query_from_image(c, image)
	query = "INSERT INTO images (image_url,image_provider_specific,image_provider_type,image_title,image_width,image_height) VALUES ("

	if image['imageUrl'] != ''
		image_url = image['imageUrl']
		query = "#{query}\'#{image_url}\'," 
	end
	if image['providerSpecific'] != ''
		image_provider_specific = image['providerSpecific'].to_json
		query = "#{query}\'#{c.escape_string(image_provider_specific)}\'," 
	end
	if image['providerType'] != ''
		image_provider_type = image['providerType']
		query = "#{query}\'#{c.escape_string(image_provider_type)}\'," 
	end
	if image['title'] == nil
		query = "#{query}\'\'" 
	else
		image_title = image['title']
		query = "#{query}\'#{c.escape_string(image_title)}\'" 
	end
	if image['width'] == nil
		query = "#{query},null" 
	else
		image_width = image['width']		
		query = "#{query},#{image_width}" 
	end
	if image['height'] == nil
		query = "#{query},null" 
	else
		image_height = image['height']
		query = "#{query},#{image_height}" 
	end

	query = "#{query})"

	query
end

