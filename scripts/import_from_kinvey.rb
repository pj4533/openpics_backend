#!/usr/bin/env ruby

require 'pg'
require 'json'
require 'uri'
require 'time'

filename = ARGV[0]
database_url = ARGV[1]

images = JSON.parse(File.read(filename));

db = URI.parse(database_url)
c = PG.connect(
	:host => db.host, 
	:port => db.port,
	:user => db.user,
	:password => db.password,
	:dbname => db.path[1..-1] )

images.each do |image|
	raw_date = image['date']

	raw_date = raw_date.gsub('ISODate("', '')
	raw_date = raw_date.gsub('")', '')

	image['date'] = Time.parse(raw_date)
end

image_urls = []

images.each do |image|
	if not image_urls.include?(image['imageUrl'])
		image_urls << image['imageUrl']
		
		query = "INSERT INTO images (date,image_url,image_provider_specific,image_provider_type,image_title,image_width,image_height) VALUES (\'#{image['date']}\',"

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

		c.exec(query)

		p "Imported #{image['title']}"
	end
end

c.close
