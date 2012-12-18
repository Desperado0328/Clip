class Stopwatch < ActiveRecord::Base
  attr_accessible :time, :paused
  
  validates :time, :numericality => true
  validates :paused, :inclusion => { :in => [true, false] }
  
  has_many :laps, :dependent => :destroy
end
