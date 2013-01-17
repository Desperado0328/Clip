# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ -> init()

init = ->
	TIME_STEP = 10 # milliseconds
	TIME_STEPS_PER_SYNC = 1000
	startSystemClock TIME_STEP, TIME_STEPS_PER_SYNC
	sync()
	
	$('.create-stopwatch-button').click(->
		$.post('/stopwatch/create', (state) =>
			createNewStopwatch $('.stopwatches'), state
		, 'json')
	)

createNewStopwatch = ($stopwatches, state) ->
	# HTML design decision per: http://stackoverflow.com/q/890004/770170
	attachEventHandlers(
		$('<div class="stopwatch stopwatch-' + state.id + '"></div>')
			.append(
				'Lap: <span class="lap-time lap-time-' + state.id + ' clock">' + constituents(state.lap_total_at_last_pause) + '</span>' +
				'<button class="destroy-stopwatch-button">X</button>' +
				'<br />' +
				'<span class="time time-' + state.id + ' clock">' + constituents(state.total_at_last_pause) + '</span>' +
				'<br />' +
				'<button class="pause-button">' +
				(if state.is_paused then 'Start' else 'Stop') + '</button>' +
				'<button class="lap-button lap-button-' + state.id + '">' +
				(if state.is_paused then 'Reset' else 'Lap') + '</button>' +
				'<div class="laps">' +
					lapsHtml(state) +
				'</div>'
			)
			.data('state', state)
			.appendTo($stopwatches)
	)

lapsHtml = (state) ->
	'<ol>' +
		(for lap, i in (state.laps.slice(0).reverse()) # loop backupwards, per: http://stackoverflow.com/a/7920999
			'<li class="lap lap-' + (state.laps.length - i) + '">Lap ' + (state.laps.length - i) + ': ' + constituents(lap.total)
		).join('') +
	'</ol>'

attachEventHandlers = ($stopwatch) ->
	# while HTTP supports GET, POST, PUT, and DELETE, HTML only supports GET and POST
	$stopwatch.children('.destroy-stopwatch-button').click( ->
		$.post('/stopwatch/destroy/' + $stopwatch.data('state').id, ->
			$stopwatch.remove()
		)
	)
	
	$stopwatch.children('.pause-button').click( ->
		stopwatchId = $stopwatch.data('state').id
		if $stopwatch.data('state').is_paused
			$.post('/stopwatch/unpause/' + stopwatchId, (state) =>
				syncOne $stopwatch, state
				$(this).text('Stop')
				$('.lap-button-' + stopwatchId).text('Lap')
			, 'json')
		else
			$.post('/stopwatch/pause/' + stopwatchId, (state) =>
				syncOne $stopwatch, state
				$(this).text('Start')
				$('.lap-button-' + stopwatchId).text('Reset')
			, 'json')
	)
	
	$stopwatch.children('.lap-button').click( ->
		stopwatchId = $stopwatch.data('state').id
		postUrl = '/stopwatch/' + (if $stopwatch.data('state').is_paused then 'reset/' else 'lap/') + stopwatchId
		$.post(postUrl, (state) ->
			syncOne $stopwatch, state
		, 'json')
	)

constituents = (milliseconds_overflowing) ->
	milliseconds_overflowing = Math.floor(milliseconds_overflowing)
	milliseconds = milliseconds_overflowing % 1000
	seconds_overflowing = Math.floor(milliseconds_overflowing / 1000)
	seconds = seconds_overflowing % 60
	minutes_overflowing = Math.floor(seconds_overflowing / 60)
	minutes = minutes_overflowing % 60
	hours_overflowing = Math.floor(minutes_overflowing / 60)
	hours = hours_overflowing # let the hours overflow because there are no higher units
	
	milliseconds = Math.floor(milliseconds / 10) # only display two decimal points
	
	[pad(hours, 2), pad(minutes, 2), pad(seconds, 2)].join(':') + '.' + pad(milliseconds, 2)
	
pad = (unpadded, length, padWith='0') ->
	retval = unpadded + '' # cast to string
	while retval.length < length
		retval = padWith + retval
	retval

sync = ->
	$.getJSON('/stopwatch', (states) ->
		syncAll states
	, 'json')

syncAll = (states) ->
	# determine which (if any) stopwatches need to be added and/or removed
	oldStopwatchIds = ($(stopwatch).data('state').id for stopwatch in $('.stopwatch'))
	newStopwatchIds = (state.id for state in states)
	{ added: addedIds, removed: removedIds } = diff oldStopwatchIds, newStopwatchIds
	statesToAdd = (state for state in states when state.id in addedIds)
	
	# add and/or remove them from the DOM
	createNewStopwatch($('.stopwatches'), state) for state in statesToAdd
	$('.stopwatch-' + id).remove() for id in removedIds
	
	# sync whatever stopwatches are left
	$('.stopwatch').each( (i, stopwatch) ->
		syncOne $(stopwatch), states[i]
	)

syncOne = ($stopwatch, state) ->
	$stopwatch.data('state', state)
	
	$stopwatch.data 'time', state.timey
	$stopwatch.data 'lapTime', state.lap_timey
	
	$stopwatch.children('.time').text(constituents(state.timey))
	$stopwatch.children('.lap-time').text(constituents(state.lap_timey))
	$stopwatch.children('.laps').html(lapsHtml(state))

# modified from: http://stackoverflow.com/a/8585449/770170
# diff( [1, 2, 3], [2, 3, 4] ) results in { added: 4, removed: 1 }
diff = (oldArray, newArray) ->
	# return
	added:
		newItem for newItem in newArray when newItem not in oldArray
	removed:
		oldItem for oldItem in oldArray when oldItem not in newArray

tick = (timeStep) ->
	$('.stopwatch').each( ->
		$this = $(this)
		
		unless $this.data('state').is_paused			
			newTime = $this.data('time') + timeStep
			newLapTime = $this.data('lapTime') + timeStep
			
			$this.data('time', newTime)
			$this.data('lapTime', newLapTime)
			
			$this.children('.time').text(constituents(newTime))
			$this.children('.lap-time').text(constituents(newLapTime))
	)

startSystemClock = (timeStep, timeStepsPerSync) ->
	counterClock = window.setInterval( (-> tick(timeStep)), timeStep)
	syncClock = window.setInterval(sync, timeStep * timeStepsPerSync)