# Pong
# (0, 0) coordinates located in upper-left corner of game window, (100, 100) in lower-right

# Avoid polluting the namespace by using a self-executing anonymous function
(->
	$(() ->
		initialize()
	)
	
	initialize = () ->
		game = {}
		game.config = config()
		game.state = state()
		game.$window = $ '.game-window'
		game.$leftPaddle = $ '.paddle.float-left'
		game.$rightPaddle = $ '.paddle.float-right'
		game.$ball = $ '.ball.float-left'
		updateCss(game)
		play(game)
	
	config = () ->
		# return:
		windowWidth: 80 # %
		windowHeight: 25 # em
		paddleWidth: 1 # em
		paddleHeight: 10 # em
		ballRadius: 1.25 # em
		leftScore: 0 # points
		rightScore: 0 # points
	
	state = () ->
		# return:
		leftPaddle:
			yPos: 0 # %
		ball:
			xPos: 0 # %
			yPos: 0 # %
			velocity: 25 # % per second
		rightPaddle:
			yPos: 0 # %
	
	updateCss = (game) ->
		game.$window.css 'width', game.config.windowWidth + '%'
		game.$window.css 'height', game.config.windowHeight + 'em'
		
		game.$leftPaddle.css 'width', game.config.paddleWidth + 'em'
		game.$leftPaddle.css 'height', game.config.paddleHeight + 'em'
		
		game.$rightPaddle.css 'width', game.config.paddleWidth + 'em'
		game.$rightPaddle.css 'height', game.config.paddleHeight + 'em'
		
		game.$ball.css 'border-radius', game.config.ballRadius + 'em'
		game.$ball.css 'width', (game.config.ballRadius * 2) + 'em'
		game.$ball.css 'height', (game.config.ballRadius * 2) + 'em'
		
	play = (game) ->
		console.log "playing"
)()

