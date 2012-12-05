# Pong
# (0, 0) coordinates located in upper-left corner of game window, (100, 100) in lower-right

;(-> # TODO Is this unnecessary in CoffeeScript?
	$(() ->
		initialize()
	)
	
	# Constants
	EM = 'em' # CSS
	PERCENT = '%' # CSS
	PX = 'px'
	UP = 38 # keyCode
	DOWN = 40 # keyCode
	LARGE_NUMBER = 1000000
	TIME_STEP = 20 # milliseconds
	
	initialize = ->
		game = {}
		game.config = config()
		game.state = state()
		game.$gameWindow = $ '.game-window'
		game.$document = $ document
		game.$leftPaddle = $ '.paddle.left'
		game.$rightPaddle = $ '.paddle.right'
		game.$ball = $ '.ball'
		updateCss(game)
		updateState(game)
		attachHandlers(game)
		play(game)
	
	# TODO Use a converter between world coordinates and screen coordinates
	config = ->
		# return:
		windowWidth: 80 # %
		windowHeight: 22 # em
		paddleWidth: 3 # %
		paddleHeight: 20 # %
		paddleXGap: 10 # %
		initPaddleVelocity: 5 # % per keypress
		ballRadius: 3 # % and em
		leftScore: 0 # points
		rightScore: 0 # points
	
	state = ->
		# return:
		leftPaddle:
			yPos: 0 # %
			yVelocity: 0 # % per time step
		ball:
			yPos: 0 # %
			xPos: 0 # %
			xVelocity: .04 * TIME_STEP # % per time step
			yVelocity: .12 * TIME_STEP # % per time step
		rightPaddle:
			yPos: 0 # %
			yVelocity: 0 * TIME_STEP # % per time step
	
	updateCss = (game) ->
		game.$gameWindow.css 'width', game.config.windowWidth + PERCENT
		game.$gameWindow.css 'height', game.config.windowHeight + EM
		
		game.$leftPaddle.css 'width', game.config.paddleWidth + PERCENT
		game.$leftPaddle.css 'height', game.config.paddleHeight + PERCENT
		game.$leftPaddle.css 'left', game.config.paddleXGap + PERCENT
		
		game.$rightPaddle.css 'width', game.config.paddleWidth + PERCENT
		game.$rightPaddle.css 'height', game.config.paddleHeight + PERCENT
		game.$rightPaddle.css 'right', game.config.paddleXGap + PERCENT
		
		resizeBall(game, gameWindowAspectRatio(game))
	
	gameWindowAspectRatio = (game) ->
		game.$gameWindow.width() / (game.$gameWindow.height())
	
	resizeBall = (game, aspectRatio) ->
		game.$ball.css 'width', (2 * game.config.ballRadius) + PERCENT # Dependent on game window width (via %)
		game.$ball.css 'height', (2 * game.config.ballRadius * aspectRatio) + PERCENT # Keep ball aspect ratio 1:1 (independent of game window aspect ratio)
		# game.$ball.css 'border-radius', (game.$ball.width() / 2) + PX # Calculate epirically because % cannot be used on border-radius
	
	updateState = (game) ->
		game.$leftPaddle.css 'top', game.state.leftPaddle.yPos + PERCENT
		game.$rightPaddle.css 'top', game.state.rightPaddle.yPos + PERCENT
		game.$ball.css 'left', game.state.ball.xPos + PERCENT
		game.$ball.css 'top', game.state.ball.yPos + PERCENT
	
	attachHandlers = (game) ->
		# Modified from: http://stackoverflow.com/a/6011119/770170
		game.$document.keydown((e)->
			switch e.which
				when DOWN
					game.state.rightPaddle.yPos += game.config.initPaddleVelocity
				when UP
					game.state.rightPaddle.yPos -= game.config.initPaddleVelocity
			game.state.rightPaddle.yPos = 0 if game.state.rightPaddle.yPos < 0
			game.state.rightPaddle.yPos = 100 - game.config.paddleHeight if game.state.rightPaddle.yPos > 100 - game.config.paddleHeight
			updateState(game)
		)
		
		$(window).resize(->
			resizeBall game, gameWindowAspectRatio(game)
		)
	
	worldToScreen = (world) ->
		console.log 'world: ' + world
		
	screenToWorld = (screen) ->
		console.log 'screen: ' + screen
	
	play = (game) ->
		console.log "playing"
		window.setInterval(->
			stepBall(game);
		, TIME_STEP)
	
	stepBall = (game) ->
		game.state.ball.xPos += game.state.ball.xVelocity
		game.state.ball.yPos += game.state.ball.yVelocity
		
		# If the ball is beyond the bounds of the game window, pull it back in and negate
		# the velocity to simulate a bounce
		diameter = 2 * game.config.ballRadius
		if game.state.ball.xPos < 0
			game.state.ball.xPos = 0
			game.state.ball.xVelocity *= -1
		if game.state.ball.xPos > 100 - diameter
			game.state.ball.xPos = 100 - diameter
			game.state.ball.xVelocity *= -1
		if game.state.ball.yPos < 0
			game.state.ball.yPos = 0
			game.state.ball.yVelocity *= -1
		if game.state.ball.yPos > 100 - diameter
			game.state.ball.yPos = 100 - diameter
			game.state.ball.yVelocity *= -1
		
		updateState(game)
)()

