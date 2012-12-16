# Modified from: http://stackoverflow.com/a/7964378/770170
require 'json'

class OwnerController < ApplicationController
	def index
		@tree = JSON.parse File.read './db/owner/corporate-ownership-trees.json'
	end
end
