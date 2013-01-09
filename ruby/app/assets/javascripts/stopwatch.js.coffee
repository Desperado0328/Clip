# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ -> init()

init = ->
	repopulateStopwatches()

# While HTTP supports GET, POST, PUT, and DELETE, HTML only supports GET and POST.
$('.destroy-stopwatch-button').click(->
	$.post('/stopwatch/destroy/' + getStopwatchId(this))
)

$('.create-stopwatch-button').click(->
	$.post '/stopwatch/create'
	repopulateStopwatches() # TODO Consider only populating the created stopwatch (in a DRY manner)
)

repopulateStopwatches = ->
	# Design decision per: http://stackoverflow.com/q/890004/770170
	$.getJSON('/stopwatch', (json) ->
		$stopwatches = $('.stopwatches')
		$stopwatches.empty()
		for stopwatch in json
			$stopwatches.append(
				'<div class="stopwatch stopwatch-' + stopwatch.id + '">' +
					'Lap: <span class="time lap-time lap-time-' + stopwatch.id + '">' + stopwatch.lap_total_at_last_pause + '</span>' +
					'<button class="destroy-stopwatch-button close-button">X</button>' +
					'<br />' +
					'<span class="time time-' + stopwatch.id + '">' + stopwatch.total_at_last_pause + '</span>' +
					'<br />' +
					'<button class="pause-button">Start</button>' +
					'<button class="lap-button">Lap</button>' +
					'<div class="laps">' +
						'<ol>' +
							'<li class="lap">Lap 3: 01:23' +
							'<li class="lap">Lap 2: 01:23' +
							'<li class="lap">Lap 1: 01:23' +
							# '<% stopwatch.laps.each do |lap| %>' +
							# '<li class="lap">Lap 4: 99:99' +
							# '<% end %>' +
						'</ol>' +
					'</div>' +
				'</div>'
			)
		$time = $('.time')
		$time.text(constituents(Number($time.text())))
	)
	# Any code down here will probably be called *before* the Ajax call has completed!

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