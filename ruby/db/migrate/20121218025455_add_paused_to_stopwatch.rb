class AddPausedToStopwatch < ActiveRecord::Migration
  def change
    add_column :stopwatches, :paused, :boolean
  end
end
