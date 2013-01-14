class Lap < ActiveRecord::Base
  belongs_to :stopwatch
  
  validates :total, :numericality => true
  
  attr_accessible :total
end
