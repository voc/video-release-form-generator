#!/usr/bin/ruby
# encoding: UTF-8

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

	first_page = true
	xml.xpath('/schedule/day').map do |day|

		day.xpath('./room').map do |room|
			pdf.start_new_page unless first_page
			first_page = false
			start_page = pdf.page_number
			pdf.font_size(14)

			tablecontent = [
				['#', 'Time', 'Speaker', 'Title', 'Signature']
			]

			room.xpath('./event').map do |event|
				tablecontent.push([
					event['id'],
					event.xpath('start').text,
					event.xpath('persons/person').map { |person| person.text }.join(', '),
					event.xpath('title').text,
					{:content => "", :borders => [:top, :bottom, :left]}
				])
			end

			pdf.bounding_box([0, pdf.bounds.top - 140], :width => pdf.bounds.width) do
				pdf.table(
					tablecontent,
					:header => true,
					:column_widths => [30, 50, 150, 339, 200]
				) do |table|
					table.cells.height = 60
					table.cells.padding = [10, 5]

					table.columns(0..3).borders = [:top, :bottom]
					table.columns(4).borders = [:top, :bottom, :left]

					table.rows(0).font_style = :bold
				end
			end

			end_page = pdf.page_number
			n_pages = end_page - start_page + 1
			pdf.repeat(start_page..end_page, :dynamic => true) do
				pdf.move_cursor_to pdf.bounds.top
				pdf.font_size(25) do
					pdf.text eventinfo[:title]+" – Video Release Form"
				end

				pdf.font_size(20) do
					pdf.text 'Day %d <i>(%s)</i>, %s – Page %d of %d' % 
						[day['index'], day['date'], room['name'], (pdf.page_number - start_page + 1), n_pages],
						:inline_format => true
				end

				pdf.pad_top(15) do
					pdf.text \
						"I/We, the undersigned, agree that <b>video footage of my talk</b> at the "+eventinfo[:title]+" "+
						"conference may be <b>broadcast, recorded, published, and archived</b> by the conference "+
						"organisers. Publication will be under the <b>Creative Commons Attribution "+
						"Share-Alike 3.0 (unported) license</b>.", :inline_format => true, :align => :justify
				end
			end
		end
	end

	puts pdf.render

end
