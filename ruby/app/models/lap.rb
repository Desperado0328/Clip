class Lap < ActiveRecord::Base
  belongs_to :stopwatch
  
  validates :time, :presence => true, :numericality => true
  validates :stopwatch_id, :presence => true
  
  attr_accessible :time #, stopwatch_id ???
end
