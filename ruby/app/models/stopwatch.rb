class Stopwatch < ActiveRecord::Base
  attr_accessible :time, :paused
  
  validates :time, :numericality => true
  validates :paused, :inclusion => { :in => [true, false] } # Don't test for presence of potentially-false values: http://stackoverflow.com/a/5219435/770170
  
  has_many :laps, :dependent => :destroy
end
