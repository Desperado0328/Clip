class StopwatchController < ApplicationController
	before_filter :init_state_change, :only => [:destroy, :get_time, :get_lap_time, :pause, :unpause, :lapss]
	after_filter :flash_to_headers
	
	def init_state_change
		@stopwatch = Stopwatch.find(params[:id])
		@now = Time.now # Please don't inline this, to ensure consistent values
		@mills_in_sec = 1000
	end
	
	# Modified from: http://stackoverflow.com/a/2729454/770170
	def flash_to_headers
		return unless request.xhr?
		response.headers['X-Flash-Notice'] = flash[:notice] unless flash[:notice].blank?
		response.headers['X-Flash-Error'] = flash[:error] unless flash[:error].blank?
		# flash.discard # The flash shouldn't appear when the page is reloaded # HACK? Commented out because it was resetting the response headers somehow
	end
	
	def index
		@stopwatches = Stopwatch.all
		# @laps = Lap.all # Goes with commented-out code below
		
		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @stopwatches }
			# Modified from: http://stackoverflow.com/a/4582989/770170
			# format.json { render json: @laps.to_json( include: :stopwatch ) } # TODO When there are laps, see if this will put them in the stopwatch JSON
			# format.json { render json: @laps.to_json( include: :stopwatch ) } # TODO When there are laps, see if this will put them in the stopwatch JSON
		end
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
				return @stopwatch.total_at_last_pause + ((@now - @stopwatch.datetime_at_last_resume) * @mills_in_sec).floor
			end
		end
		redirect_to stopwatch_path
	end
	
	def get_lap_time
		ActiveRecord::Base.transaction do
			if @stopwatch.is_paused
				return @stopwatch.lap_total_at_last_pause
			else
				return @stopwatch.lap_total_at_last_pause + ((@now - @stopwatch.lap_datetime_at_last_resume) * @mills_in_sec).floor
			end
		end
		redirect_to stopwatch_path
	end
	
	def pause
		ActiveRecord::Base.transaction do
			break if @stopwatch.is_paused
			
			milliseconds = @stopwatch.total_at_last_pause + ((@now - @stopwatch.datetime_at_last_resume) * @mills_in_sec).floor
			lap_milliseconds = @stopwatch.lap_total_at_last_pause + ((@now - @stopwatch.lap_datetime_at_last_resume) * @mills_in_sec).floor
			
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
				:datetime_at_last_resume => @now,
				:lap_datetime_at_last_resume => @now,
				:is_paused => false
			)
		end
		
		respond_with_json
	end
	
	def lapss # Temporarily renamed due to symbol name conflicts with commented-out code in #index
		ActiveRecord::Base.transaction do
			lap_milliseconds = @stopwatch.lap_total_at_last_pause + ((@now - @stopwatch.lap_datetime_at_last_resume) * @mills_in_sec).floor
			Lap.create( :total => lap_milliseconds )
			@stopwatch.update_attributes(
				:lap_total_at_last_pause => 0,
				:lap_datetime_at_last_resume => @now
			)
		end
		redirect_to stopwatch_path
	end
	
	def respond_with_json
		respond_to do |format|
			format.json { render json: @stopwatch }
			# Modified from: http://stackoverflow.com/a/4582989/770170
			# format.json { render json: @laps.to_json( include: :stopwatch ) } # TODO When there are laps, see if this will put them in the stopwatch JSON
			# format.json { render json: @laps.to_json( include: :stopwatch ) } # TODO When there are laps, see if this will put them in the stopwatch JSON
		end
	end
end
