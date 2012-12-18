class Stopwatch < ActiveRecord::Base
  attr_accessible :time
  
  validates :time, :presence => true
  
   has_many :laps, :dependent => :destroy
end
