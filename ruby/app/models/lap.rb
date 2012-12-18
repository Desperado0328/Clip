class Lap < ActiveRecord::Base
  belongs_to :stopwatch
  
  attr_accessible :time
end
