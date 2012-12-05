# Pong
# (0, 0) coordinates located in upper-left corner of game window, (100, 100) in lower-right

# Avoid polluting the namespace by using a self-executing anonymous function
(->
	$(() ->
		initialize()
	)
	
	em = 'em'
	percent = '%'
	
	initialize = ->
		game = {}
		game.config = config()
		game.state = state()
		game.$window = $ '.game-window'
		game.$leftPaddle = $ '.paddle.left'
		game.$rightPaddle = $ '.paddle.right'
		game.$ball = $ '.ball'
		updateCss(game)
		updateState(game)
		play(game)
	
	# TODO Have a converter between world coordinates and screen coordinates
	config = ->
		# return:
		windowWidth: 80 # %
		windowHeight: 25 # em
		paddleWidth: 1 # em
		paddleHeight: 7 # em
		paddleGap: 10 # percent
		ballRadius: 1.25 # em
		leftScore: 0 # points
		rightScore: 0 # points
	
	state = ->
		# return:
		leftPaddle:
			yPos: 0 # %
		ball:
			yPos: 0 # %
			xPos: 0 # %
			velocity: 25 / 1000.0 # % per millisecond
		rightPaddle:
			yPos: 0 # %
	
	updateCss = (game) ->
		game.$window.css 'width', game.config.windowWidth + percent
		game.$window.css 'height', game.config.windowHeight + em
		
		game.$leftPaddle.css 'width', game.config.paddleWidth + em
		game.$leftPaddle.css 'height', game.config.paddleHeight + em
		game.$leftPaddle.css 'left', game.config.paddleGap + percent
		
		game.$rightPaddle.css 'width', game.config.paddleWidth + em
		game.$rightPaddle.css 'height', game.config.paddleHeight + em
		game.$rightPaddle.css 'right', game.config.paddleGap + percent
		
		game.$ball.css 'border-radius', game.config.ballRadius + em
		game.$ball.css 'width', (2 * game.config.ballRadius) + em
		game.$ball.css 'height', (2 * game.config.ballRadius) + em
	
	updateState = (game) ->
		game.$leftPaddle.css 'top', game.state.leftPaddle.yPos + percent
		game.$rightPaddle.css 'top', game.state.rightPaddle.yPos + percent
		game.$ball.css 'left', game.state.ball.xPos + percent
		game.$ball.css 'top', game.state.ball.yPos + percent
	
	play = (game) ->
		console.log "playing"
		
	worldToScreen = (world) ->
		console.log "world: " + world
		
	screenToWorld = (screen) ->
		console.log "screen: " + screen
)()

