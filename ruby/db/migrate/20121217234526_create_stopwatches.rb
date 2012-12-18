class CreateStopwatches < ActiveRecord::Migration
  def change
    create_table :stopwatches do |t|
      t.integer :current_time

      t.timestamps
    end
  end
end
