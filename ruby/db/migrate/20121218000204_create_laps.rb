class CreateLaps < ActiveRecord::Migration
  def change
    create_table :laps do |t|
      t.integer :time

      t.timestamps
    end
  end
end
