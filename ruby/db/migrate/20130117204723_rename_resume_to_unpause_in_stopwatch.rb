class RenameResumeToUnpauseInStopwatch < ActiveRecord::Migration
	# Per: http://stackoverflow.com/a/1992045/770170
	def change
		rename_column :stopwatches, :datetime_at_last_resume, :datetime_at_last_unpause
		rename_column :stopwatches, :lap_datetime_at_last_resume, :lap_datetime_at_last_unpause
	end
end
