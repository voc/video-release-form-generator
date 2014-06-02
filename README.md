Frab-Based Release-Form-Generator
=================================

This script will generate you a pdf for speakers to sign of that their talk will be stremed, recorded and published. It generates a staple of pages for each day & room to be laid out in the rooms.

Usage
-----
Install the required gems, then call it with your Frab/Pentabarf compatible xml and save the pdf:

	bundle
	./generate-form.rb http://sotm-eu.org/export.xml > sotm-eu-form.pdf

For some events with rooms that are not recorded (like workshop-rooms), you may pass a list of rooms. The script will generate only pages for the rooms mentioned there

	./generate-form.rb http://www.fossgis.de/konferenz/2014/programm/schedule.de.xml H1 H2 H3 > fossgis-form.pdf
