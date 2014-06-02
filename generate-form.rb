#!/usr/bin/ruby
require 'open-uri'
require 'nokogiri'
require 'prawn'

if ARGV.length < 1 then
	$stderr.puts "call with schedule-xml url and pipe output to a pdf-file like this:"
	$stderr.puts "  ./generate-form.rb http://sotm-eu.org/export.xml > sotm-eu-form.pdf"
	exit
end

url = ARGV[0]
open(url) do |f|
	xml = Nokogiri::XML(f)
	
	pdf = Prawn::Document.new(
		:page_size => "A4",
		:page_layout => :landscape
	)

	eventinfo = {}
	xml.xpath('/schedule/conference').tap do |conference|
		eventinfo = {
			:title => conference.xpath('title').text,
			:subtitle => conference.xpath('subtitle').text,
			:venue => conference.xpath('venue').text,
			:city => conference.xpath('city').text
		}
	end

	pdf.text eventinfo[:title]
	pdf.text eventinfo[:subtitle]
	pdf.text eventinfo[:venue]
	pdf.text eventinfo[:city]

	xml.xpath('/schedule/day').map do |day|
		day.xpath('./room').map do |room|
			pdf.start_new_page
			pdf.text day['date']+' '+room['name']
		end
	end

	puts pdf.render

end
