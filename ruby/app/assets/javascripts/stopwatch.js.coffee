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
		(if state.is_paused then ' disabled="disabled"' else '') + '>Lap</button>' +
		'<div class="laps">' +
			lapsHtml(state) +
		'</div>'
	)
	$stopwatch.data 'state', state
	attachEventHandlers $stopwatch

lapsHtml = (state) ->
	'<ol>' +
		(for lap, i in (state.laps.slice(0).reverse()) # Loop backupwards, per: http://stackoverflow.com/a/7920999
			'<li class="lap lap-' + (state.laps.length - i) + '">Lap ' + (state.laps.length - i) + ': ' + constituents(lap.total)
		).join('') +
	'</ol>'

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
				$(this).text('Stop')
				$stopwatch.children('.lap-button').removeAttr('disabled')
			, 'json')
		else
			$.post('stopwatch/pause/' + stopwatchId, (state) =>
				$stopwatch.data('state', state)
				$stopwatch.data 'time', state.total_at_last_pause
				$stopwatch.data 'lapTime', state.lap_total_at_last_pause
				$stopwatch.children('.time').text(constituents(state.total_at_last_pause))
				$stopwatch.children('.lap-time').text(constituents(state.lap_total_at_last_pause))
				$(this).text('Start')
				$stopwatch.children('.lap-button').attr('disabled', 'disabled')
			, 'json')
	)
	
	$stopwatch.children('.lap-button').click( ->
		stopwatchId = $stopwatch.data('state').id
		$.post('stopwatch/lap/' + stopwatchId, (state) =>
			$stopwatch.data('state', state)
			$stopwatch.data 'lapTime', 0
			syncOne $stopwatch, state
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

sync = ->
	$.post('stopwatch', (states) ->
		syncAll states
		
		$('.stopwatch').each( (i, stopwatch) ->
			syncOne $(stopwatch), states[i]
		)
	, 'json')

syncAll = (states) ->
	# Determine which (if any) stopwatches need to be added and/or removed
	oldStopwatchIds = ($(stopwatch).data('state').id for stopwatch in $('.stopwatch'))
	newStopwatchIds = (state.id for state in states)
	{ added: addedIds, removed: removedIds } = diff oldStopwatchIds, newStopwatchIds
	statesToAdd = (state for state in states when state.id in addedIds)
	
	# Add and/or remove them from the DOM
	createNewStopwatch($('.stopwatches'), state) for state in statesToAdd
	$('.stopwatch-' + id).remove() for id in removedIds

syncOne = ($stopwatch, state) ->
	$stopwatch.data('state', state)
	
	# TODO Refactor to put the "new Date()" and dateDiff calls on the server
	now = new Date()
	time = state.total_at_last_pause
	lapTime = state.lap_total_at_last_pause
	unless state.is_paused
		time += dateDiff(now, new Date(state.datetime_at_last_resume))
		lapTime += dateDiff(now, new Date(state.lap_datetime_at_last_resume))
	
	$stopwatch.data 'time', time
	$stopwatch.data 'lapTime', lapTime
	
	$stopwatch.children('.laps').html(lapsHtml(state))

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