class Stopwatch < ActiveRecord::Base
  attr_accessible :time, :paused
  
  validates :time, :presence => true, :numericality => true
  validates :paused, :presence => true, :inclusion => { :in => [true, false] }
  
  has_many :laps, :dependent => :destroy
end
