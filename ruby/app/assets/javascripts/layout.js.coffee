# Place all global behaviors and hooks here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

$('.close-button').click(->
	$(this).parent().fadeOut('fast', ->
		# Animation complete.
	)
)

# Modified from: http://stackoverflow.com/a/2729454/770170
$(document).ajaxComplete((event, request) ->
	flash =
		notice: request.getResponseHeader('X-Flash-Notice')
		error: request.getResponseHeader('X-Flash-Error')
	
	for key, value of flash
		if value
			$('.flash-container').append(
				'<div class="flash ' + key + '">' + value +
					'<button type="button" class="close-button">X</button>' + 
				'</div>'
			)
)