#!/usr/bin/env ruby

require 'pg'
require 'json'
require 'uri'
require 'time'
require '../lib/helpers'

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

images.reverse.each do |image|
	if not image_urls.include?(image['imageUrl'])
		image_urls << image['imageUrl']

		query = get_insert_query_from_image(c,image)

		c.exec(query)

		p "Imported #{image['title']}"
	end
end

c.close
