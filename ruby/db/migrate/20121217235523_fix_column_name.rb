class FixColumnName < ActiveRecord::Migration
  # Modified from: http://stackoverflow.com/a/1992045/770170
  def change
	rename_column :stopwatches, :current_time, :time
  end
end
