class RenameAndAddColumnsInStopwatchesAndLaps < ActiveRecord::Migration
  # Per: http://stackoverflow.com/a/1992045/770170
  def change
	rename_column :stopwatches, :paused, :is_paused
	
	rename_column :stopwatches, :time, :total_at_last_pause
	rename_column :laps,        :time, :lap_total_at_last_pause
	
	# Per: http://stackoverflow.com/a/3929047/770170
	add_column :stopwatches, :datetime_at_last_resume, :datetime
	add_column :laps,        :lap_datetime_at_last_resume, :datetime
  end
end
