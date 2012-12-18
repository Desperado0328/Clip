class AddForeignKey < ActiveRecord::Migration
  # Modified from: http://guides.rubyonrails.org/association_basics.html#creating-foreign-keys-for-belongs_to-associations
  # Modified from: http://guides.rubyonrails.org/association_basics.html#has_one-foreign_key
  # Modified from: http://guides.rubyonrails.org/migrations.html#creating-a-standalone-migration
  def change
    add_column :laps, :stopwatch_id, :integer
  end
end
