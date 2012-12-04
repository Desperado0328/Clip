class HomeController < ApplicationController
  def index
	flash[:notice] = 'Notice was successfully notified.'
  end
end