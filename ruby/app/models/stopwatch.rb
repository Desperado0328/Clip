class Stopwatch < ActiveRecord::Base
	attr_accessible :is_paused,
		:total_at_last_pause,
		:datetime_at_last_resume,
		:lap_datetime_at_last_resume,
		:lap_total_at_last_pause

	validates :is_paused, :inclusion => { :in => [true, false] } # Never test for presence of potentially-false values: http://stackoverflow.com/a/5219435/770170
	validates :total_at_last_pause, :numericality => true
	validates :lap_total_at_last_pause, :numericality => true

	has_many :laps, :dependent => :destroy
end
