require 'open-uri'

class RssController < ApplicationController
	def index
		@xml = '<rss>'

		# Modified from http://nokogiri.org/tutorials/parsing_an_html_xml_document.html
		@youtube = Nokogiri::HTML(open('http://www.youtube.com/user/YouTube/feed'))
	end
end
