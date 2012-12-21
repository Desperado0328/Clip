class AddLapTotalColumnToStopwatch < ActiveRecord::Migration
  def change
    add_column :stopwatches, :lap_total_at_last_pause, :integer, :default => 0, :null => false
  end
end
