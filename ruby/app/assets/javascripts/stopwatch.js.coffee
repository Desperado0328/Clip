# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$ -> init()

init = ->
	$('.create-stopwatch-button').click(->
		$.post '/stopwatch/create'
		repopulateStopwatches() # TODO Only populate the created stopwatch (in a DRY manner) (for performance and so it can be highlighted for a few seconds)
	)
	
	repopulateStopwatches() # Ajax! Any code after this line had better not depend on it

repopulateStopwatches = ->
	# Design decision per: http://stackoverflow.com/q/890004/770170
	$.getJSON('/stopwatch', (json) ->
		$stopwatches = $('.stopwatches')
		$stopwatches.empty()
		for stopwatch in json
			$stopwatches.append(
				'<div class="stopwatch stopwatch-' + stopwatch.id + '"></div>'
			)
			$stopwatch = $('.stopwatch-' + stopwatch.id) # The object that was just appended
			$stopwatch.append(
				'Lap: <span class="time lap-time lap-time-' + stopwatch.id + '">' + constituents(stopwatch.lap_total_at_last_pause) + '</span>' +
				'<button class="destroy-stopwatch-button">X</button>' +
				'<br />' +
				'<span class="time main-time time-' + stopwatch.id + '">' + constituents(stopwatch.total_at_last_pause) + '</span>' +
				'<br />' +
				'<button class="' +
				# Modified from: http://stackoverflow.com/a/10146123/770170
				(if stopwatch.is_paused then 'resume' else 'pause') + '-button">' +
				(if stopwatch.is_paused then 'Resume' else 'Pause') + '</button>' +
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
			$stopwatch.data('json', stopwatch)
		
		attachEventHandlers()
		startTimer()
	)
	# WARNING: Any code placed out here will probably be called *before* the Ajax call has
	# completed, and cannot depend on it being completed.

attachEventHandlers = ->
	# While HTTP supports GET, POST, PUT, and DELETE, HTML only supports GET and POST.
	$('.destroy-stopwatch-button').click( ->
		stopwatchId = getStopwatchId this
		$.post('/stopwatch/destroy/' + stopwatchId, ->
			$('.stopwatch-' + stopwatchId).remove()
		)
	)
	
	$('.resume-button').click( ->
		stopwatchId = getStopwatchId this
		$.post('stopwatch/resume/' + stopwatchId, (json) =>
			$(this)
				.removeClass('resume-button')
				.addClass('pause-button')
				.text('Pause')
		, 'json')
	)
	
	$('.pause-button').click( ->
		stopwatchId = getStopwatchId this
		$.post('stopwatch/pause/' + stopwatchId, (json) =>
			$(this)
				.removeClass('pause-button')
				.addClass('resume-button')
				.text('Resume')
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

startTimer = ->
	timer = window.setInterval( ->
		now = new Date()
		$stopwatches = $('.stopwatch')
		$stopwatches.each((index) ->
			$this = $(this)
			json = $this.data('json')
			unless json.is_paused
				time = json.total_at_last_pause + dateDiff(now, new Date(json.datetime_at_last_resume))
				lapTime = json.lap_total_at_last_pause + dateDiff(now, new Date(json.lap_datetime_at_last_resume))
				$this.children('.main-time').text(constituents(time))
				$this.children('.lap-time').text(constituents(lapTime))
		)
	, 1000)

dateDiff = (present, past) ->
	Math.floor(present - past)