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
	$.getJSON('/stopwatch', (states) ->
		$stopwatches = $('.stopwatches')
		$stopwatches.empty()
		for state in states
			createNewStopwatch $stopwatches, state
		sync()
		startSystemClock()
	)
	# WARNING: Any code placed out here will probably be called *before* the Ajax call has
	# completed and cannot depend on it being completed.

createNewStopwatch = ($stopwatches, state) ->
	$stopwatches.append(
		'<div class="stopwatch stopwatch-' + state.id + '"></div>'
	)
	$stopwatch = $('.stopwatch-' + state.id) # The object that was just appended
	$stopwatch.append(
		'Lap: <span class="lap-time lap-time-' + state.id + ' clock">' + constituents(state.lap_total_at_last_pause) + '</span>' +
		'<button class="destroy-stopwatch-button">X</button>' +
		'<br />' +
		'<span class="time time-' + state.id + ' clock">' + constituents(state.total_at_last_pause) + '</span>' +
		'<br />' +
		'<button class="pause-button">' +
		(if state.is_paused then 'Start' else 'Stop') + '</button>' +
		'<button class="lap-button"' +
		(if state.is_paused then ' disabled') + '>Lap</button>' +
		'<div class="laps">' +
			'<ol>' +
				'<li class="lap">Lap 3: 01:23' +
				'<li class="lap">Lap 2: 01:23' +
				'<li class="lap">Lap 1: 01:23' +
				# '<% state.laps.each do |lap| %>' +
				# '<li class="lap">Lap 4: 99:99' +
				# '<% end %>' +
			'</ol>' +
		'</div>'
	)
	$stopwatch.data 'state', state
	attachEventHandlers $stopwatch

attachEventHandlers = ($stopwatch) ->
	# While HTTP supports GET, POST, PUT, and DELETE, HTML only supports GET and POST.
	$stopwatch.children('.destroy-stopwatch-button').click( ->
		$.post('/stopwatch/destroy/' + $stopwatch.data('state').id, ->
			$stopwatch.remove()
		)
	)
	
	$stopwatch.children('.pause-button').click( ->
		stopwatchId = $stopwatch.data('state').id
		# TODO duplicate code
		if $stopwatch.data('state').is_paused
			$.post('stopwatch/unpause/' + stopwatchId, (state) =>
				$stopwatch.data('state', state)
				$stopwatch.data 'time', state.total_at_last_pause
				$stopwatch.data 'lapTime', state.lap_total_at_last_pause
				$stopwatch.children('.time').text(constituents(state.total_at_last_pause))
				$stopwatch.children('.lap-time').text(constituents(state.lap_total_at_last_pause))
				$(this).text('Stop')
			, 'json')
		else
			$.post('stopwatch/pause/' + stopwatchId, (state) =>
				$stopwatch.data('state', state)
				$stopwatch.data 'time', state.total_at_last_pause
				$stopwatch.data 'lapTime', state.lap_total_at_last_pause
				$stopwatch.children('.time').text(constituents(state.total_at_last_pause))
				$stopwatch.children('.lap-time').text(constituents(state.lap_total_at_last_pause))
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
	
	milliseconds = Math.floor(milliseconds / 10) # only display two decimal points
	
	[pad(hours, 2), pad(minutes, 2), pad(seconds, 2)].join(':') + '.' + pad(milliseconds, 2)
	
pad = (unpadded, length, padWith='0') ->
	retval = unpadded + '' # cast to string
	while retval.length < length
		retval = padWith + retval
	retval

# TODO This doesn't work if a stopwatch was added or deleted outside the current window
sync = ->
	$.post('stopwatch', (states) ->
		# Determine if any stopwatches were added or removed
		oldStopwatchIds = ($(stopwatch).data('state').id for stopwatch in $('.stopwatch'))
		newStopwatchIds = (state.id for state in states)
		{ added: addedIds, removed: removedIds } = diff oldStopwatchIds, newStopwatchIds
		statesToAdd = (state for state in states when state.id in addedIds)
		# Add and/or remove from the DOM
		createNewStopwatch($('.stopwatches'), state) for state in statesToAdd
		$('.stopwatch-' + id).remove() for id in removedIds
		
		$('.stopwatch').each( (i, stopwatch) ->
			$stopwatch = $(stopwatch)
			$stopwatch.data('state', states[i])
			
			# TODO Refactor to put the "new Date()" and dateDiff calls on the server
			now = new Date()
			time = states[i].total_at_last_pause
			lapTime = states[i].lap_total_at_last_pause
			unless states[i].is_paused
				time += dateDiff(now, new Date(states[i].datetime_at_last_resume))
				lapTime += dateDiff(now, new Date(states[i].lap_datetime_at_last_resume))
			
			$stopwatch.data 'time', time
			$stopwatch.data 'lapTime', lapTime
		)
	, 'json')

# Modified from: http://stackoverflow.com/a/8585449/770170
# diff([1,2,3],[2,3,4]) results in {added:4,removed:1}
diff = (oldArray, newArray) ->
	# return
	added:
		newItem for newItem in newArray when newItem not in oldArray
	removed:
		oldItem for oldItem in oldArray when oldItem not in newArray

dateDiff = (present, past) ->
	Math.floor(present - past)

startSystemClock = ->
	counterClock = window.setInterval( ->
		$('.stopwatch').each( ->
			$this = $(this)
			
			unless $this.data('state').is_paused			
				newTime = $this.data('time') + TIME_STEP
				newLapTime = $this.data('lapTime') + TIME_STEP
				
				$this.data('time', newTime)
				$this.data('lapTime', newLapTime)
				
				$this.children('.time').text(constituents(newTime))
				$this.children('.lap-time').text(constituents(newLapTime))
		)
	, TIME_STEP)
	
	syncClock = window.setInterval( ->
		sync()
	, TIME_STEP * 1000)