# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

TIME_STEP = 10 # milliseconds # TODO Global

$ -> init()

init = ->
	$('.create-stopwatch-button').click(->
		$.post '/stopwatch/create'
		repopulateStopwatches() # TODO Only populate the created stopwatch (in a DRY manner) (for performance and so it can be highlighted for a few seconds)
	)
	
	repopulateStopwatches() # Ajax! Any code after this line had better not depend on it

repopulateStopwatches = ->
	# Design decision per: http://stackoverflow.com/q/890004/770170
	$.getJSON('/stopwatch', (response) ->
		$stopwatches = $('.stopwatches')
		$stopwatches.empty()
		for stopwatch in response
			$stopwatches.append(
				'<div class="stopwatch stopwatch-' + stopwatch.id + '"></div>'
			)
			$stopwatch = $('.stopwatch-' + stopwatch.id) # The object that was just appended
			$stopwatch.append(
				'Lap: <span class="lap-time lap-time-' + stopwatch.id + ' clock">' + constituents(stopwatch.lap_total_at_last_pause) + '</span>' +
				'<button class="destroy-stopwatch-button">X</button>' +
				'<br />' +
				'<span class="time time-' + stopwatch.id + ' clock">' + constituents(stopwatch.total_at_last_pause) + '</span>' +
				'<br />' +
				'<button class="pause-button">' +
				(if stopwatch.is_paused then 'Start' else 'Stop') + '</button>' +
				'<button class="lap-button"' +
				(if stopwatch.is_paused then ' disabled') + '>Lap</button>' +
				'<div class="laps">' +
					'<ol>' +
						'<li class="lap">Lap 3: 01:23' +
						'<li class="lap">Lap 2: 01:23' +
						'<li class="lap">Lap 1: 01:23' +
						# '<% stopwatch.laps.each do |lap| %>' +
						# '<li class="lap">Lap 4: 99:99' +
						# '<% end %>' +
					'</ol>' +
				'</div>'
			)
			$stopwatch.data 'response', stopwatch
			attachEventHandlers $stopwatch
		
		sync()
		startSystemClock()
	)
	# WARNING: Any code placed out here will probably be called *before* the Ajax call has
	# completed and cannot depend on it being completed.

attachEventHandlers = ($stopwatch) ->
	# While HTTP supports GET, POST, PUT, and DELETE, HTML only supports GET and POST.
	$stopwatch.children('.destroy-stopwatch-button').click( ->
		$.post('/stopwatch/destroy/' + $stopwatch.data('response').id, ->
			$stopwatch.remove()
		)
	)
	
	$stopwatch.children('.pause-button').click( ->
		stopwatchId = $stopwatch.data('response').id
		if $stopwatch.data('response').is_paused
			$.post('stopwatch/unpause/' + stopwatchId, (response) =>
				$stopwatch.data('response', response)
				$(this).text('Stop')
			, 'json')
		else
			$.post('stopwatch/pause/' + stopwatchId, (response) =>
				$stopwatch.data('response', response)
				$(this).text('Start')
			, 'json')
	)

constituents = (milliseconds_overflowing) ->
	milliseconds_overflowing = Number milliseconds_overflowing
	milliseconds = milliseconds_overflowing % 1000
	seconds_overflowing = Math.floor(milliseconds_overflowing / 1000)
	seconds = seconds_overflowing % 60
	minutes_overflowing = Math.floor(seconds_overflowing / 60)
	minutes = minutes_overflowing % 60
	hours_overflowing = Math.floor(minutes_overflowing / 60)
	hours = hours_overflowing # Let the hours overflow because there are no higher units.
	
	milliseconds = Math.floor(milliseconds / 10) # Trim off the last digit
	
	[pad(hours, 2), pad(minutes, 2), pad(seconds, 2)].join(':') + '.' + pad(milliseconds, 2)
	
pad = (unpadded, length, padWith='0') ->
	retval = unpadded + '' # Cast to string
	while retval.length < length
		retval = padWith + retval
	retval

# TODO This doesn't work if a stopwatch was added or deleted outside the current window
sync = ->
	$.post('stopwatch', (response) ->
		$('.stopwatch').each( (i, stopwatch) ->
			$stopwatch = $(stopwatch)
			$stopwatch.data('response', response[i])
			
			# TODO Refactor to put the "new Date()" and dateDiff calls on the server
			now = new Date()
			time = response[i].total_at_last_pause
			lapTime = response[i].lap_total_at_last_pause
			unless response[i].is_paused
				time += dateDiff(now, new Date(response[i].datetime_at_last_resume))
				lapTime += dateDiff(now, new Date(response[i].lap_datetime_at_last_resume))
			
			$stopwatch.data 'time', time
			$stopwatch.data 'lapTime', lapTime
		)
	, 'json')

dateDiff = (present, past) ->
	Math.floor(present - past)

startSystemClock = ->
	clock = window.setInterval( ->
		$('.stopwatch').each( ->
			$this = $(this)
			
			unless $this.data('response').is_paused			
				newTime = $this.data('time') + TIME_STEP
				newLapTime = $this.data('lapTime') + TIME_STEP
				
				$this.data('time', newTime)
				$this.data('lapTime', newLapTime)
				
				$this.children('.time').text(constituents(newTime))
				$this.children('.lap-time').text(constituents(newLapTime))
		)
	, TIME_STEP)