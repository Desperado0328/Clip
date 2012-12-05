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
	P = 80 # keyCode
	DOWN = 40 # keyCode
	LARGE_NUMBER = 1000000
	TIME_STEP = 20 # milliseconds
	
	initialize = ->
		game = {}
		game.config = config()
		game.state = state()
		game.$gameWindow = $ '.game-window'
		game.$window = $ window
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
		longestSide: .8 # % / 100
		aspectRatio: 3 / 2 # width / height
		paddleWidth: 3 # %
		paddleHeight: 20 # %
		paddleXGap: 10 # %
		initPaddleVelocity: 5 # % per keypress
		ballRadius: 3 # % (and em for border-radius)
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
		paused: false
		intervalId: null
	
	updateCss = (game) ->
		resizeGameWindow game, windowAspectRatio(game)
		
		game.$leftPaddle.css 'width', game.config.paddleWidth + PERCENT
		game.$leftPaddle.css 'height', game.config.paddleHeight + PERCENT
		game.$leftPaddle.css 'left', game.config.paddleXGap + PERCENT
		
		game.$rightPaddle.css 'width', game.config.paddleWidth + PERCENT
		game.$rightPaddle.css 'height', game.config.paddleHeight + PERCENT
		game.$rightPaddle.css 'right', game.config.paddleXGap + PERCENT
	
	windowAspectRatio = (game) ->
		game.$window.width() / game.$window.height()
	
	resizeGameWindow = (game, windowAspectRatio) ->
		if game.config.aspectRatio < windowAspectRatio
			# maximize height because there isn't much height to work with
			game.$gameWindow.css 'height', (game.config.longestSide * game.$window.height()) + PX
			game.$gameWindow.css 'width', game.$gameWindow.height() * game.config.aspectRatio + PX
		else
			# maximize width because there isn't much width to work with
			game.$gameWindow.css 'width', (game.config.longestSide * game.$window.width()) + PX
			game.$gameWindow.css 'height', game.$gameWindow.width() / game.config.aspectRatio + PX
		
		resizeBall(game)
	
	resizeBall = (game) ->
		game.$ball.css 'width', (2 * game.config.ballRadius) + PERCENT # Dependent on game window width (via %)
		game.$ball.css 'height', (2 * game.config.ballRadius * game.config.aspectRatio) + PERCENT # Keep ball aspect ratio 1:1 (independent of game window aspect ratio)
		# #inefficient game.$ball.css 'border-radius', (game.$ball.width() / 2) + PX # Calculate epirically because % cannot be used on border-radius
	
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
				when P
					if !game.state.paused
						game.state.paused = true
						clearInterval(game.state.intervalId)
					else
						game.state.paused = false
						play(game)
			game.state.rightPaddle.yPos = 0 if game.state.rightPaddle.yPos < 0
			game.state.rightPaddle.yPos = 100 - game.config.paddleHeight if game.state.rightPaddle.yPos > 100 - game.config.paddleHeight
			updateState(game)
		)
		
		$(window).resize(->
			resizeGameWindow game, windowAspectRatio(game)
		)
	
	worldToScreen = (world) ->
		console.log 'world: ' + world
		
	screenToWorld = (screen) ->
		console.log 'screen: ' + screen
	
	play = (game) ->
		game.state.intervalId = window.setInterval(->
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

