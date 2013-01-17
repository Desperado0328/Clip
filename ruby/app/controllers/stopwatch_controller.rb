class StopwatchController < ApplicationController	
	# iPhone stopwatch operation (ignoring article's advice):
	# http://www.leancrew.com/all-this/2009/07/iphone-stopwatch-ui-oddity/

	# Database transaction code modified from:
	# http://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html

	before_filter :get_stopwatch, :only => [:destroy, :pause, :unpause, :lap, :reset]
	after_filter :flash_to_headers
	
	def index
		@stopwatches = Stopwatch.all
		
		respond_to do |format|
			format.html # index.html.erb
			format.json { render :json => @stopwatches.to_json( :include => :laps ) } # Modified from: http://stackoverflow.com/a/4582989/770170
		end
	end
	
	def create
		@stopwatch = Stopwatch.create(
			:is_paused => true,
			:total_at_last_pause => 0,
			:lap_total_at_last_pause => 0,
			:datetime_at_last_unpause => nil,
			:lap_datetime_at_last_unpause => nil
		)
		
		redirect_to stopwatch_path
	end
	
	def destroy
		@stopwatch.destroy
		
		redirect_to stopwatch_path
	end
	
	def pause
		ActiveRecord::Base.transaction do
			break if @stopwatch.is_paused
			
			milliseconds = @stopwatch.total_at_last_pause + since(@stopwatch.datetime_at_last_unpause)
			lap_milliseconds = @stopwatch.lap_total_at_last_pause + since(@stopwatch.lap_datetime_at_last_unpause)
			
			@stopwatch.update_attributes(
				:total_at_last_pause => milliseconds,
				:lap_total_at_last_pause => lap_milliseconds,
				:is_paused => true
			)
		end
		
		respond_with_json
	end
	
	def unpause
		ActiveRecord::Base.transaction do
			break unless @stopwatch.is_paused
			
			@stopwatch.update_attributes(
				:datetime_at_last_unpause => @now,
				:lap_datetime_at_last_unpause => @now,
				:is_paused => false
			)
		end
		
		respond_with_json
	end
	
	def lap
		ActiveRecord::Base.transaction do
			if @stopwatch.is_paused
				lap_milliseconds = @stopwatch.lap_total_at_last_pause
			else
				lap_milliseconds = @stopwatch.lap_total_at_last_pause + since(@stopwatch.lap_datetime_at_last_unpause)
			end
			
			@stopwatch.laps.create( :total => lap_milliseconds )
			@stopwatch.update_attributes(
				:lap_total_at_last_pause => 0,
				:lap_datetime_at_last_unpause => @now
			)
		end
		
		respond_with_json
	end
	
	def reset
		ActiveRecord::Base.transaction do
			@stopwatch.laps.destroy_all
			@stopwatch.update_attributes(
				:total_at_last_pause => 0,
				:lap_total_at_last_pause => 0,
				:datetime_at_last_unpause => @now,
				:lap_datetime_at_last_unpause => @now
			)
		end
		
		respond_with_json
	end
	
	def get_stopwatch
		@stopwatch = Stopwatch.find(params[:id])
		@now = Time.now # Please don't inline this, to ensure consistent values
		@mills_in_sec = 1000
	end
	
	# Similar to Time#since, but returns milliseconds and uses @now (defined in
	# StopwatchController#get_stopwatch)
	def since (datetime)
		((@now - datetime) * @mills_in_sec).floor
	end
	
	# Modified from: http://stackoverflow.com/a/2729454/770170
	def flash_to_headers
		return unless request.xhr?
		response.headers['X-Flash-Notice'] = flash[:notice] unless flash[:notice].blank?
		response.headers['X-Flash-Error'] = flash[:error] unless flash[:error].blank?
		# flash.discard # The flash shouldn't appear when the page is reloaded # HACK? Commented out because it was resetting the response headers somehow
	end
	
	def respond_with_json
		respond_to do |format|
			format.json { render :json => @stopwatch.to_json( :include => :laps ) } # Modified from: http://stackoverflow.com/a/4582989/770170
		end
	end
end
