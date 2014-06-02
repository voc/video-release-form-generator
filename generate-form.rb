#!/usr/bin/ruby
# encoding: UTF-8

# http reader
require 'open-uri'

# xml parser
require 'nokogiri'

# pdf formatter
require 'prawn'



# test for required argument
if ARGV.length < 1 then
	$stderr.puts "call with schedule-xml url and pipe output to a pdf-file like this:"
	$stderr.puts "  ./generate-form.rb http://sotm-eu.org/export.xml > sotm-eu-form.pdf"
	exit
end

# extract the url
url = ARGV.shift

# interpret remaining arguments as room-filter
rooms = ARGV
$stderr.puts "room-filter active: ["+rooms.join(', ')+']' if not rooms.empty?

# convert room names to uppercase
rooms.map!(&:upcase)

# download and open it
open(url) do |f|
	# parse the resulting xml
	xml = Nokogiri::XML(f)

	# create a new A4-Landscape sized pdf-document
	pdf = Prawn::Document.new(
		:page_size => "A4",
		:page_layout => :landscape
	)

	# extract the event-info from the header of the schedule-xml
	eventinfo = {}
	xml.xpath('/schedule/conference').tap do |conference|
		eventinfo = {
			:title => conference.xpath('title').text,
			:subtitle => conference.xpath('subtitle').text,
			:venue => conference.xpath('venue').text,
			:city => conference.xpath('city').text
		}
	end

	# avoid page-break on the first page
	first_page = true

	# iterate through all days and all rooms
	xml.xpath('/schedule/day').map do |day|
		day.xpath('./room').map do |room|
			# don't add a page for this room if there are no events on that day
			next if room.xpath('./event').length == 0

			# skip if a room-filter is present and the room is not in that filter
			next if not rooms.empty? and not rooms.include?(room['name'].upcase)

			# add a page-break unless we're on the first page
			pdf.start_new_page unless first_page
			first_page = false

			# record the page-number where that room starts
			start_page = pdf.page_number

			# set default font-size
			pdf.font_size(14)

			# start the table with its header
			tablecontent = [
				['#', 'Time', 'Speaker', 'Title', 'Signature']
			]

			# iterate through all events
			room.xpath('./event').map do |event|
				# push a row to that table
				tablecontent.push([
					event['id'],
					event.xpath('start').text,

					# concatanate person-names with a comma
					event.xpath('persons/person').map { |person| person.text }.join(', '),
					event.xpath('title').text,

					# empty cell for the signature
					""
				])
			end

			# define a bounding-box that will leave room (140 points) at the top of the page for
			# the text-header. that bounding box will reserve those 140 points on each page the
			# table flows onto, so on each page there will be 140 points free space
			pdf.bounding_box([0, pdf.bounds.top - 140], :width => pdf.bounds.width) do
				# paint the table into this bounding-box
				pdf.table(
					tablecontent,

					# repeat the first row on each page
					:header => true,

					# specify column width in points
					:column_widths => [30, 50, 150, 339, 200]
				) do |table|
					# post-parse-pre-layout formatting rules

					# force cell-height and padding
					table.cells.height = 60
					table.cells.padding = [10, 5]

					# specify borders for the normal cells and for the signature cell
					table.columns(0..3).borders = [:top, :bottom]
					table.columns(4).borders = [:top, :bottom, :left]

					# format the header-row as bold
					table.rows(0).font_style = :bold
				end
			end

			# record last page the table flew onto
			end_page = pdf.page_number

			# add a repeater for all the pages the table for this room has filled
			# :dynamic makes prawn reevaluate the repeated block on each page, allowing us to do
			# page-number calculations
			pdf.repeat(start_page..end_page, :dynamic => true) do
				# move to the top of that page
				pdf.move_cursor_to pdf.bounds.top

				# big title
				pdf.font_size(25) do
					pdf.text eventinfo[:title]+" – Video Release Form"
				end

				# not so big subtitle
				pdf.font_size(20) do
					pdf.text 'Day %d <i>(%s)</i>, %s – Page %d of %d' % [
						day['index'],
						day['date'],
						room['name'],
						
						# page-index in the set of pages the per-room-and-day-table filled
						# in other words: page-number per room and day
						(pdf.page_number - start_page + 1),

						# number of pages the table required
						end_page - start_page + 1
					], :inline_format => true
				end

				# acknowledgement text with a little extra padding
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

	# render to stdout
	puts pdf.render
end
