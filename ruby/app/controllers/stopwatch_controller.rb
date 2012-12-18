class StopwatchController < ApplicationController
	def index
		@stopwatches = Stopwatch.all
	end
	
	def create
		@stopwatch = Stopwatch.new({ :time => 0, :paused => false })
		if @stopwatch.save
			flash[:notice] = 'Stopwatch was successfully created.'
		else
			flash[:error] = ['Could not create a new stopwatch for the following reason: ', @stopwatch.errors]
		end
		redirect_to stopwatch_path
	end
	
	def destroy
		@stopwatch = Stopwatch.find(params[:id])
		if @stopwatch.destroy
			flash[:notice] = 'Stopwatch was successfully deleted.'
		else
			flash[:error] = 'Could not delete stopwatch.'
		end
		redirect_to stopwatch_path
  end
end
