# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ -> init()

init = ->
	$('.time').text(constituents(Number($('.time').text())))

constituents = (milliseconds_overflowing) ->
	milliseconds = milliseconds_overflowing % 1000
	seconds_overflowing = Math.floor(milliseconds_overflowing / 1000)
	seconds = seconds_overflowing % 60
	minutes_overflowing = Math.floor(seconds_overflowing / 60)
	minutes = minutes_overflowing % 60
	hours_overflowing = Math.floor(minutes_overflowing / 60)
	hours = hours_overflowing # Let the hours overflow because there are no higher units.
	
	[pad(hours, 2), pad(minutes, 2), pad(seconds, 2)].join(':') + '.' + pad(milliseconds, 3)
	
pad = (unpadded, length, padWith='0') ->
	retval = unpadded + '' # Cast to string
	while retval.length < length
		retval = padWith + retval
	retval