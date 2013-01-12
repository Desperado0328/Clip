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
	$.getJSON('/stopwatch', (stopwatchStates) ->
		$stopwatches = $('.stopwatches')
		$stopwatches.empty()
		for stopwatchState in stopwatchStates
			$stopwatches.append(
				'<div class="stopwatch stopwatch-' + stopwatchState.id + '"></div>'
			)
			$stopwatch = $('.stopwatch-' + stopwatchState.id) # The object that was just appended
			$stopwatch.append(
				'Lap: <span class="lap-time lap-time-' + stopwatchState.id + ' clock">' + constituents(stopwatchState.lap_total_at_last_pause) + '</span>' +
				'<button class="destroy-stopwatch-button">X</button>' +
				'<br />' +
				'<span class="time time-' + stopwatchState.id + ' clock">' + constituents(stopwatchState.total_at_last_pause) + '</span>' +
				'<br />' +
				'<button class="pause-button">' +
				(if stopwatchState.is_paused then 'Start' else 'Stop') + '</button>' +
				'<button class="lap-button"' +
				(if stopwatchState.is_paused then ' disabled') + '>Lap</button>' +
				'<div class="laps">' +
					'<ol>' +
						'<li class="lap">Lap 3: 01:23' +
						'<li class="lap">Lap 2: 01:23' +
						'<li class="lap">Lap 1: 01:23' +
						# '<% stopwatchState.laps.each do |lap| %>' +
						# '<li class="lap">Lap 4: 99:99' +
						# '<% end %>' +
					'</ol>' +
				'</div>'
			)
			$stopwatch.data 'stopwatchState', stopwatchState
			attachEventHandlers $stopwatch
		
		sync()
		startSystemClock()
	)
	# WARNING: Any code placed out here will probably be called *before* the Ajax call has
	# completed and cannot depend on it being completed.

attachEventHandlers = ($stopwatch) ->
	# While HTTP supports GET, POST, PUT, and DELETE, HTML only supports GET and POST.
	$stopwatch.children('.destroy-stopwatch-button').click( ->
		$.post('/stopwatch/destroy/' + $stopwatch.data('stopwatchState').id, ->
			$stopwatch.remove()
		)
	)
	
	$stopwatch.children('.pause-button').click( ->
		stopwatchId = $stopwatch.data('stopwatchState').id
		# TODO duplicate code
		if $stopwatch.data('stopwatchState').is_paused
			$.post('stopwatch/unpause/' + stopwatchId, (stopwatchState) =>
				$stopwatch.data('stopwatchState', stopwatchState)
				$stopwatch.data 'time', stopwatchState.total_at_last_pause
				$stopwatch.data 'lapTime', stopwatchState.lap_total_at_last_pause
				$stopwatch.children('.time').text(constituents(stopwatchState.total_at_last_pause))
				$stopwatch.children('.lap-time').text(constituents(stopwatchState.lap_total_at_last_pause))
				$(this).text('Stop')
			, 'json')
		else
			$.post('stopwatch/pause/' + stopwatchId, (stopwatchState) =>
				$stopwatch.data('stopwatchState', stopwatchState)
				$stopwatch.data 'time', stopwatchState.total_at_last_pause
				$stopwatch.data 'lapTime', stopwatchState.lap_total_at_last_pause
				$stopwatch.children('.time').text(constituents(stopwatchState.total_at_last_pause))
				$stopwatch.children('.lap-time').text(constituents(stopwatchState.lap_total_at_last_pause))
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
	$.post('stopwatch', (stopwatchStates) ->
		# Determine which stopwatches need to be added or removed
		domIds = ($(stopwatch).data('stopwatchState').id for stopwatch in $('.stopwatch'))
		responseIds = (stopwatch.id for stopwatch in stopwatchStates) # Modified from: http://stackoverflow.com/a/7398529/770170
		{ add: add, remove: remove } = diff(domIds, responseIds)
		stopwatchStatesToAdd = (stopwatchState for stopwatchState in stopwatchStates when stopwatchState.id in add)
		stopwatchStatesToRemove = (stopwatchState for stopwatchState in stopwatchStates when stopwatchState.id in remove)
		addStates stopwatchStatesToAdd
		removeStates stopwatchStatesToRemove
		
		$('.stopwatch').each( (i, stopwatch) ->
			$stopwatch = $(stopwatch)
			$stopwatch.data('stopwatchState', stopwatchStates[i])
			
			# TODO Refactor to put the "new Date()" and dateDiff calls on the server
			now = new Date()
			time = stopwatchStates[i].total_at_last_pause
			lapTime = stopwatchStates[i].lap_total_at_last_pause
			unless stopwatchStates[i].is_paused
				time += dateDiff(now, new Date(stopwatchStates[i].datetime_at_last_resume))
				lapTime += dateDiff(now, new Date(stopwatchStates[i].lap_datetime_at_last_resume))
			
			$stopwatch.data 'time', time
			$stopwatch.data 'lapTime', lapTime
		)
	, 'json')

# Modified from: http://stackoverflow.com/a/8585449/770170
# diff([1, 2, 3], [2, 3, 4]) results in { add: 4, remove: 1 }
diff = (oldIds, newIds) ->
	# return
	add:
		newId for newId in newIds when newId not in oldIds
	remove:
		oldId for oldId in oldIds when oldId not in newIds

addStates = (stopwatchStates) ->
	console.log

removeStates = (stopwatchStates) ->
	console.log

dateDiff = (present, past) ->
	Math.floor(present - past)

startSystemClock = ->
	clock = window.setInterval( ->
		$('.stopwatch').each( ->
			$this = $(this)
			
			unless $this.data('stopwatchState').is_paused			
				newTime = $this.data('time') + TIME_STEP
				newLapTime = $this.data('lapTime') + TIME_STEP
				
				$this.data('time', newTime)
				$this.data('lapTime', newLapTime)
				
				$this.children('.time').text(constituents(newTime))
				$this.children('.lap-time').text(constituents(newLapTime))
		)
	, TIME_STEP)