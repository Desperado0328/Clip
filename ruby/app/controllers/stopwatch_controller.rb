class StopwatchController < ApplicationController
	before_filter :init_state_change, :only => [:destroy, :get_time, :get_lap_time, :pause, :resume, :lap]
	after_filter :flash_to_headers
	
	def init_state_change
		@stopwatch = Stopwatch.find(params[:id])
		@now = Time.now # Please don't inline this, to ensure consistent values
	end
	
	# Modified from: http://stackoverflow.com/a/2729454/770170
	def flash_to_headers
		return unless request.xhr?
		response.headers['X-Flash-Notice'] = flash[:notice] # TODO unless flash[:notice].blank?
		response.headers['X-Flash-Error'] = flash[:error] # TODO unless flash[:error].blank?
		
		flash.discard # don't want the flash to appear when you reload page
	end
	
	def index
		@stopwatches = Stopwatch.all
	end
	
	# iPhone stopwatch operation (but don't follow the article's advice):
	# http://www.leancrew.com/all-this/2009/07/iphone-stopwatch-ui-oddity/
	
	# Database transaction code modified from:
	# http://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html
	
	def create
		@stopwatch = Stopwatch.new(
			:is_paused => true,
			:total_at_last_pause => 0,
			:lap_total_at_last_pause => 0,
			:datetime_at_last_resume => nil,
			:lap_datetime_at_last_resume => nil
		)
		if @stopwatch.save
			flash[:notice] = 'Stopwatch was successfully created.'
		else
			flash[:error] = ['Could not create a new stopwatch because: ', @stopwatch.errors]
		end
		redirect_to stopwatch_path
	end
	
	def destroy
		if @stopwatch.destroy
			flash[:notice] = 'Stopwatch was successfully deleted.'
		else
			flash[:error] = ['Could not delete stopwatch because: ', @stopwatch.errors]
		end
		redirect_to stopwatch_path
	end
	
	def get_time
		ActiveRecord::Base.transaction do
			if @stopwatch.is_paused
				return @stopwatch.total_at_last_pause
			else
				return @stopwatch.total_at_last_pause + (@now - @stopwatch.datetime_at_last_resume)
			end
		end
	end
	
	def get_lap_time
		ActiveRecord::Base.transaction do
			if @stopwatch.is_paused
				return @stopwatch.lap_total_at_last_pause
			else
				return @stopwatch.lap_total_at_last_pause + (@now - @stopwatch.lap_datetime_at_last_resume)
			end
		end
	end
	
	def pause
		ActiveRecord::Base.transaction do
			# TODO Assuming Time.now - Time.past is in milliseconds
			milliseconds = @stopwatch.total_at_last_pause + (@now - @stopwatch.datetime_at_last_resume)
			lap_milliseconds = @stopwatch.lap_total_at_last_pause + (@now - @stopwatch.lap_datetime_at_last_resume)
			
			@stopwatch.update_attributes(
				:total_at_last_pause => milliseconds,
				:lap_total_at_last_pause => lap_milliseconds,
				:is_paused => true
			)
		end
	end
	
	def resume
		ActiveRecord::Base.transaction do
			@stopwatch.update_attributes(
				:datetime_at_last_resume => @now,
				:lap_datetime_at_last_resume => @now,
				:is_paused => false
			)
		end
	end
	
	def lap
		ActiveRecord::Base.transaction do
			# TODO Assuming Time.now - Time.past is in milliseconds
			lap_milliseconds = @stopwatch.lap_total_at_last_pause + (@now - @stopwatch.lap_datetime_at_last_resume)
			Lap.create( :total => lap_milliseconds )
			@stopwatch.update_attributes(
				:lap_total_at_last_pause => 0,
				:lap_datetime_at_last_resume => @now
			)
		end
	end
end
