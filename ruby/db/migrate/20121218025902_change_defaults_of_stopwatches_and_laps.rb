class ChangeDefaultsOfStopwatchesAndLaps < ActiveRecord::Migration
  # Modified from: http://stackoverflow.com/a/5682165/770170
  def change
    change_column :stopwatches, :time, :integer, :null => false, :default => 0
	change_column :stopwatches, :paused, :boolean, :null => false, :default => true
	
	change_column :laps, :time, :integer, :null => false, :default => 0
	change_column :laps, :stopwatch_id, :integer, :null => false, :default => 0
  end
end
