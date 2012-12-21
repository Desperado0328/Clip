class MoveColumnsFromLapsToStopwatches < ActiveRecord::Migration
	def change
		add_column :stopwatches, :lap_datetime_at_last_resume, :datetime
		remove_column :laps, :lap_datetime_at_last_resume # Per: http://stackoverflow.com/a/2963582/770170
		
		rename_column :laps, :lap_total_at_last_pause, :total
	end
end
