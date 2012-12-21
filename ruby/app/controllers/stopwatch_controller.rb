class StopwatchController < ApplicationController
	def index
		@stopwatches = Stopwatch.all
	end
	
	# iPhone stopwatch operation (but don't follow the article's advice):
	# http://www.leancrew.com/all-this/2009/07/iphone-stopwatch-ui-oddity/
	
	def create
		@stopwatch = Stopwatch.new({
			:is_paused => true,
			:total_at_last_pause => 0,
			:lap_total_at_last_pause => 0,
			:datetime_at_last_resume => nil,
			:lap_datetime_at_last_resume => nil
		})
		if @stopwatch.save
			flash[:notice] = 'Stopwatch was successfully created.'
		else
			flash[:error] = ['Could not create a new stopwatch because: ', @stopwatch.errors]
		end
		redirect_to stopwatch_path
	end
	
	def destroy
		@stopwatch = Stopwatch.find(params[:id])
		if @stopwatch.destroy
			flash[:notice] = 'Stopwatch was successfully deleted.'
		else
			flash[:error] = ['Could not delete stopwatch because: ', @stopwatch.errors]
		end
		redirect_to stopwatch_path
  end
end
