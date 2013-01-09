# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ -> init()

init = ->
	$('.time').text(constituents(Number($('.time').text())))

# While HTTP supports GET, POST, PUT, and DELETE, HTML only supports GET and POST.
$('.destroy-stopwatch-button').click(->
	$.post('/stopwatch/destroy/' + getStopwatchId(this))
)

$('.create-stopwatch-button').click(->
	$.post '/stopwatch/create'
	location.reload() # TODO Call an Ajax-y refresh instead
)

getStopwatches = ->
	$.get '/stopwatch/all'

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

getStopwatchId = (_this) ->
	stopwatchId = -1
	classList = $(_this).parent().attr('class').split(/\s+/)
	# Modified from: http://stackoverflow.com/a/1227309/770170
	$.each(classList, (index, klass) ->
		if klass.indexOf('stopwatch-') != -1 # String.contains(), per: http://stackoverflow.com/a/1789952/770170
			stopwatchId = klass.substring('stopwatch-'.length) # Modified from: http://stackoverflow.com/a/4126795/770170
	)
	stopwatchId