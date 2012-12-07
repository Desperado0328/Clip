# Pong
# (0, 0) coordinates located in upper-left corner of game window, (100, 100) in lower-right

;(-> # TODO Is this unnecessary in CoffeeScript?
	class Pong
		constructor: (@leftPaddle, @rightPaddle, @ball) ->
			# Constants:
			@PERCENT = '%' # CSS
			@PX = 'px'
			@keyCodes = # http://www.cambiaresearch.com/articles/15/javascript-char-codes-key-codes
				UP: 38
				DOWN: 40
				P: 80
				A: 65
				Z: 90
			@TIME_STEP = 20 # milliseconds
			
			# Instance variables
			@game = {}
			
			@init()
		
		init: ->
			# Actually do the work of initializing:
			@initGame()
			@updateCss()
			@updateState()
			@attachHandlers()
			@play()
		
		initGame: ->
			@game.config = @config()
			@game.state = @state()
			@game.$gameWindow = $ '.game-window'
			@game.$window = $ window
			@game.$document = $ document
			@game.$leftPaddle = $ '.paddle.left'
			@game.$rightPaddle = $ '.paddle.right'
			@game.$ball = $ '.ball'
		
		config: ->
			aspectRatio = 3 / 2
			ballWidth = 4 # % (and em for border-radius)
			
			# The ball aspect ratio is the inverse of the game window aspect ratio, canceling
			# it out and resulting in a 1:1 aspect ratio (a square ball).
			ballHeight = ballWidth * aspectRatio # %
			
			# return:
			longestSide: .8 # % / 100
			aspectRatio: aspectRatio # width / height
			paddleWidth: 3 # %
			paddleHeight: 20 # %
			paddleXGap: 10 # %
			initPaddleVelocity: 5 # % per keypress
			ballWidth: ballWidth
			ballHeight: ballHeight
			baselineBallVelocity: 0.06 * @TIME_STEP # % per time step
			leftScore: 0 # points
			rightScore: 0 # points
		
		state: ->
			# return:
			leftPaddle:
				yPos: 0 # %
				yVelocity: 0.05 * @TIME_STEP # % per time step
			ball:
				yPos: 50 # %
				xPos: 50 # %
				xVelocity: 0.02 * @TIME_STEP # % per time step
				yVelocity: 0.06 * @TIME_STEP # % per time step
			rightPaddle:
				yPos: 0 # %
				yVelocity: 0.00 * @TIME_STEP # % per time step
			paused: false
			intervalId: null
		
		updateCss: ->
			@resizeGameWindow @windowAspectRatio()
			
			@game.$leftPaddle.css 'width', @game.config.paddleWidth + @PERCENT
			@game.$leftPaddle.css 'height', @game.config.paddleHeight + @PERCENT
			@game.$leftPaddle.css 'left', @game.config.paddleXGap + @PERCENT
			
			@game.$rightPaddle.css 'width', @game.config.paddleWidth + @PERCENT
			@game.$rightPaddle.css 'height', @game.config.paddleHeight + @PERCENT
			@game.$rightPaddle.css 'right', @game.config.paddleXGap + @PERCENT
		
		windowAspectRatio: ->
			@game.$window.width() / @game.$window.height()
		
		resizeGameWindow: (windowAspectRatio) ->
			if @game.config.aspectRatio < windowAspectRatio
				# maximize height because there isn't much height to work with
				@game.$gameWindow.css 'height', (@game.config.longestSide * @game.$window.height()) + @PX
				@game.$gameWindow.css 'width', @game.$gameWindow.height() * @game.config.aspectRatio + @PX
			else
				# maximize width because there isn't much width to work with
				@game.$gameWindow.css 'width', (@game.config.longestSide * @game.$window.width()) + @PX
				@game.$gameWindow.css 'height', @game.$gameWindow.width() / @game.config.aspectRatio + @PX
			
			@resizeBall()
		
		resizeBall: ->
			@game.$ball.css 'width', @game.config.ballWidth + @PERCENT
			@game.$ball.css 'height', @game.config.ballHeight + @PERCENT
			# #cannot be rendered fast enough @game.$ball.css 'border-radius', (@game.$ball.width() / 2) + @PX # Calculate epirically because % cannot be used on border-radius
		
		updateState: ->
			@game.$leftPaddle.css 'top', @game.state.leftPaddle.yPos + @PERCENT
			@game.$rightPaddle.css 'top', @game.state.rightPaddle.yPos + @PERCENT
			@game.$ball.css 'left', @game.state.ball.xPos + @PERCENT
			@game.$ball.css 'top', @game.state.ball.yPos + @PERCENT
		
		attachHandlers: ->
			# Modified from: http://stackoverflow.com/a/6011119/770170
			@game.$document.keydown((e) =>
				switch e.which
					when @keyCodes.DOWN
						@game.state.rightPaddle.yPos += @game.config.initPaddleVelocity unless @game.state.paused
					when @keyCodes.UP
						@game.state.rightPaddle.yPos -= @game.config.initPaddleVelocity unless @game.state.paused
					when @keyCodes.Z
						@game.state.leftPaddle.yPos += @game.config.initPaddleVelocity unless @game.state.paused
					when @keyCodes.A
						@game.state.leftPaddle.yPos -= @game.config.initPaddleVelocity unless @game.state.paused
					when @keyCodes.P
						if !@game.state.paused
							@game.state.paused = true
							clearInterval @game.state.intervalId
							@game.state.intervalId = null # invalidate for any future sanity checks
						else
							@game.state.paused = false
							@play()
				@game.state.rightPaddle.yPos = 0 if @game.state.rightPaddle.yPos < 0
				@game.state.rightPaddle.yPos = 100 - @game.config.paddleHeight if @game.state.rightPaddle.yPos > 100 - @game.config.paddleHeight
				@updateState()
			)
			
			$(window).resize(->
				@resizeGameWindow @windowAspectRatio()
			)
		
		play: ->
			@game.state.intervalId = window.setInterval(=>
				@stepBall()
				@stepAI()
			, @TIME_STEP)
		
		stepBall: ->
			@game.state.ball.xPos += @game.state.ball.xVelocity
			@game.state.ball.yPos += @game.state.ball.yVelocity
			@bounceOffEdges()
			@bounceOffPaddles()
			@updateState()
		
		stepAI: ->
			@game.state.leftPaddle.yPos += @game.state.leftPaddle.yVelocity
			if @game.state.leftPaddle.yPos < 0
				@game.state.leftPaddle.yPos = 0
				@game.state.leftPaddle.yVelocity *= -1
			if @game.state.leftPaddle.yPos > (100 - @game.config.paddleHeight)
				@game.state.leftPaddle.yPos = 100 - @game.config.paddleHeight
				@game.state.leftPaddle.yVelocity *= -1
		
		bounceOffEdges: ->
			# If the ball is beyond the bounds of the game window, pull it back in and negate
			# the velocity to simulate a bounce
			if @game.state.ball.xPos < 0
				@game.state.ball.xPos = 0
				@game.state.ball.xVelocity *= -1
			if @game.state.ball.xPos > 100 - @game.config.ballWidth
				@game.state.ball.xPos = 100 - @game.config.ballWidth
				@game.state.ball.xVelocity *= -1
			if @game.state.ball.yPos < 0
				@game.state.ball.yPos = 0
				@game.state.ball.yVelocity *= -1
			if @game.state.ball.yPos > 100 - @game.config.ballHeight
				@game.state.ball.yPos = 100 - @game.config.ballHeight
				@game.state.ball.yVelocity *= -1
		
		# TODO DRY
		bounceOffPaddles: ->
			whereBallHitRightPaddle = @getWhereBallHitRightPaddle()
			if whereBallHitRightPaddle
				@game.state.ball.xPos = 100 - @game.config.paddleXGap - @game.config.paddleWidth - @game.config.ballWidth
				@game.state.ball.xVelocity *= -1
				@game.state.ball.yVelocity = @game.config.baselineBallVelocity * whereBallHitRightPaddle
			
			whereBallHitLeftPaddle = @getWhereBallHitLeftPaddle()
			if whereBallHitLeftPaddle
				@game.state.ball.xPos = @game.config.paddleXGap + @game.config.paddleWidth
				@game.state.ball.xVelocity *= -1
				@game.state.ball.yVelocity = @game.config.baselineBallVelocity * whereBallHitLeftPaddle
		
		getWhereBallHitRightPaddle: ->
			paddleTopYPos = @game.state.rightPaddle.yPos - @game.config.ballHeight
			paddleBottomYPos = @game.state.rightPaddle.yPos + @game.config.paddleHeight
			return null unless @game.state.ball.xVelocity > 0
			return null unless @game.state.ball.xPos > (100 - @game.config.paddleXGap - @game.config.paddleWidth - @game.config.ballWidth)
			return null unless paddleTopYPos < @game.state.ball.yPos < paddleBottomYPos
			
			distanceFromTop = @game.state.ball.yPos - paddleTopYPos
			paddleHeightWithExtra = paddleBottomYPos - paddleTopYPos
			fractionAlongPaddle = distanceFromTop / paddleHeightWithExtra
			
			# Move the zero-point and size of 0.0...0.5...1.0 to -1.0...0.0...1.0
			return (fractionAlongPaddle - 0.5) * 2
		
		getWhereBallHitLeftPaddle: ->
			paddleTopYPos = @game.state.leftPaddle.yPos - @game.config.ballHeight
			paddleBottomYPos = @game.state.leftPaddle.yPos + @game.config.paddleHeight
			return null unless @game.state.ball.xVelocity < 0
			return null unless @game.state.ball.xPos < (@game.config.paddleXGap + @game.config.paddleWidth)
			return null unless paddleTopYPos < @game.state.ball.yPos < paddleBottomYPos
			
			distanceFromTop = @game.state.ball.yPos - paddleTopYPos
			paddleHeightWithExtra = paddleBottomYPos - paddleTopYPos
			fractionAlongPaddle = distanceFromTop / paddleHeightWithExtra
			
			# Move the zero-point and size of 0.0...0.5...1.0 to -1.0...0.0...1.0
			return (fractionAlongPaddle - 0.5) * 2
		
	class Paddle
		constructor: ->
			# do nothing
	
	class Ball
		constructor: ->
			# do nothing
	
	$ -> new Pong new Paddle, new Paddle, new Ball
)()