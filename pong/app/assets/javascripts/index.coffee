# Pong
# (0, 0) coordinates located in upper-left corner of game window, (100, 100) in lower-right

;(-> # TODO Is this unnecessary in CoffeeScript?
	# TODO Don't make thi global
	GAME_WINDOW_ASPECT_RATIO = 3 / 2 # width / height
	
	$ -> new Pong new Paddle('.paddle.left'), new Paddle('.paddle.right'), new Ball('.ball', GAME_WINDOW_ASPECT_RATIO)
	
	class Animatable
		constructor: ->
			@TIME_STEP = 20 # milliseconds
	
	class Paddle extends Animatable
		constructor: (locator) ->
			super()
			
			@$self = $ locator
			
			# TODO Make this a static property (see http://arcturo.github.com/library/coffeescript/03_classes.html)
			@config =
				paddleWidth: 3 # %
				paddleHeight: 20 # %
				paddleXGap: 10 # %
				initPaddleVelocity: 5 # % per keypress
			
			@state =
				yPos: 0 # %
				yVelocity: 0.05 * @TIME_STEP # % per time step
	
	class Ball extends Animatable
		constructor: (locator, gameWindowAspectRatio) ->
			super()
			
			@$self = $ locator
			
			ballWidth = 4 # % (and em for border-radius)			
			# The ball aspect ratio is the inverse of the game window aspect ratio, canceling
			# it out and resulting in a 1:1 aspect ratio (a square ball).
			ballHeight = ballWidth * gameWindowAspectRatio # %
			
			@config =
				ballWidth: ballWidth
				ballHeight: ballHeight
				baselineBallVelocity: 0.06 * @TIME_STEP # % per time step
			
			@state =
				yPos: 50 # %
				xPos: 50 # %
				xVelocity: 0.02 * @TIME_STEP # % per time step
				yVelocity: 0.06 * @TIME_STEP # % per time step
	
	class Pong
		constructor: (@leftPaddle, @rightPaddle, @ball) ->
			# Constants
			@PERCENT = '%' # CSS
			@PX = 'px'
			@keyCodes = # http://www.cambiaresearch.com/articles/15/javascript-char-codes-key-codes
				UP: 38
				DOWN: 40
				P: 80
				A: 65
				Z: 90
			
			# Instance variables
			@config = @getConfig()
			@state = @getState()
			@$gameWindow = $ '.game-window'
			@$window = $ window
			@$document = $ document
			
			# Actually do the work of initializing
			@init()
		
		init: ->
			@updateCss()
			@updateState()
			@attachHandlers()
			@play()
		
		getConfig: ->
			# return:
			longestSide: .8 # % / 100
			aspectRatio: GAME_WINDOW_ASPECT_RATIO
			leftScore: 0 # points
			rightScore: 0 # points
		
		getState: ->
			# return:
			paused: false
			intervalId: null
		
		updateCss: ->
			@resizeGameWindow @windowAspectRatio()
			
			@leftPaddle.$self.css 'width', @leftPaddle.config.paddleWidth + @PERCENT
			@leftPaddle.$self.css 'height', @leftPaddle.config.paddleHeight + @PERCENT
			@leftPaddle.$self.css 'left', @leftPaddle.config.paddleXGap + @PERCENT
			
			@rightPaddle.$self.css 'width', @rightPaddle.config.paddleWidth + @PERCENT
			@rightPaddle.$self.css 'height', @rightPaddle.config.paddleHeight + @PERCENT
			@rightPaddle.$self.css 'right', @rightPaddle.config.paddleXGap + @PERCENT
		
		windowAspectRatio: ->
			@$window.width() / @$window.height()
		
		resizeGameWindow: (windowAspectRatio) ->
			if @config.aspectRatio < windowAspectRatio
				# maximize height because there isn't much height to work with
				@$gameWindow.css 'height', (@config.longestSide * @$window.height()) + @PX
				@$gameWindow.css 'width', @$gameWindow.height() * @config.aspectRatio + @PX
			else
				# maximize width because there isn't much width to work with
				@$gameWindow.css 'width', (@config.longestSide * @$window.width()) + @PX
				@$gameWindow.css 'height', @$gameWindow.width() / @config.aspectRatio + @PX
			
			@resizeBall()
		
		resizeBall: ->
			@ball.$self.css 'width', @ball.config.ballWidth + @PERCENT
			@ball.$self.css 'height', @ball.config.ballHeight + @PERCENT
			# #cannot be rendered fast enough @ball.$self.css 'border-radius', (@ball.$self.width() / 2) + @PX # Calculate epirically because % cannot be used on border-radius
		
		updateState: ->
			@leftPaddle.$self.css 'top', @leftPaddle.state.yPos + @PERCENT
			@rightPaddle.$self.css 'top', @rightPaddle.state.yPos + @PERCENT
			@ball.$self.css 'left', @ball.state.xPos + @PERCENT
			@ball.$self.css 'top', @ball.state.yPos + @PERCENT
		
		attachHandlers: ->
			# Modified from: http://stackoverflow.com/a/6011119/770170
			@$document.keydown((e) =>
				switch e.which
					when @keyCodes.DOWN
						@rightPaddle.state.yPos += @rightPaddle.config.initPaddleVelocity unless @state.paused
					when @keyCodes.UP
						@rightPaddle.state.yPos -= @rightPaddle.config.initPaddleVelocity unless @state.paused
					when @keyCodes.Z
						@leftPaddle.state.yPos += @leftPaddle.config.initPaddleVelocity unless @state.paused
					when @keyCodes.A
						@leftPaddle.state.yPos -= @leftPaddle.config.initPaddleVelocity unless @state.paused
					when @keyCodes.P
						if !@state.paused
							@state.paused = true
							clearInterval @state.intervalId
							@state.intervalId = null # invalidate for any future sanity checks
						else
							@state.paused = false
							@play()
				@rightPaddle.state.yPos = 0 if @rightPaddle.state.yPos < 0
				@rightPaddle.state.yPos = 100 - @rightPaddle.config.paddleHeight if @rightPaddle.state.yPos > 100 - @rightPaddle.config.paddleHeight
				@updateState()
			)
			
			$(window).resize( =>
				@resizeGameWindow @windowAspectRatio()
			)
		
		play: ->
			@state.intervalId = window.setInterval( =>
				@stepBall()
				@stepAI()
			, @ball.TIME_STEP)
		
		stepBall: ->
			@ball.state.xPos += @ball.state.xVelocity
			@ball.state.yPos += @ball.state.yVelocity
			@bounceOffEdges()
			@bounceOffPaddles()
			@updateState()
		
		stepAI: ->
			@leftPaddle.state.yPos += @leftPaddle.state.yVelocity
			if @leftPaddle.state.yPos < 0
				@leftPaddle.state.yPos = 0
				@leftPaddle.state.yVelocity *= -1
			if @leftPaddle.state.yPos > (100 - @leftPaddle.config.paddleHeight)
				@leftPaddle.state.yPos = 100 - @leftPaddle.config.paddleHeight
				@leftPaddle.state.yVelocity *= -1
		
		bounceOffEdges: ->
			# If the ball is beyond the bounds of the game window, pull it back in and negate
			# the velocity to simulate a bounce
			if @ball.state.xPos < 0
				@ball.state.xPos = 0
				@ball.state.xVelocity *= -1
			if @ball.state.xPos > 100 - @ball.config.ballWidth
				@ball.state.xPos = 100 - @ball.config.ballWidth
				@ball.state.xVelocity *= -1
			if @ball.state.yPos < 0
				@ball.state.yPos = 0
				@ball.state.yVelocity *= -1
			if @ball.state.yPos > 100 - @ball.config.ballHeight
				@ball.state.yPos = 100 - @ball.config.ballHeight
				@ball.state.yVelocity *= -1
		
		# TODO DRY
		bounceOffPaddles: ->
			whereBallHitRightPaddle = @getWhereBallHitRightPaddle()
			if whereBallHitRightPaddle
				@ball.state.xPos = 100 - @rightPaddle.config.paddleXGap - @rightPaddle.config.paddleWidth - @ball.config.ballWidth
				@ball.state.xVelocity *= -1
				@ball.state.yVelocity = @ball.config.baselineBallVelocity * whereBallHitRightPaddle
			
			whereBallHitLeftPaddle = @getWhereBallHitLeftPaddle()
			if whereBallHitLeftPaddle
				@ball.state.xPos = @rightPaddle.config.paddleXGap + @rightPaddle.config.paddleWidth
				@ball.state.xVelocity *= -1
				@ball.state.yVelocity = @ball.config.baselineBallVelocity * whereBallHitLeftPaddle
		
		getWhereBallHitRightPaddle: ->
			paddleTopYPos = @rightPaddle.state.yPos - @ball.config.ballHeight
			paddleBottomYPos = @rightPaddle.state.yPos + @rightPaddle.config.paddleHeight
			return null unless @ball.state.xVelocity > 0
			return null unless @ball.state.xPos > (100 - @rightPaddle.config.paddleXGap - @rightPaddle.config.paddleWidth - @ball.config.ballWidth)
			return null unless paddleTopYPos < @ball.state.yPos < paddleBottomYPos
			
			distanceFromTop = @ball.state.yPos - paddleTopYPos
			paddleHeightWithExtra = paddleBottomYPos - paddleTopYPos
			fractionAlongPaddle = distanceFromTop / paddleHeightWithExtra
			
			# Move the zero-point and size of 0.0...0.5...1.0 to -1.0...0.0...1.0
			return (fractionAlongPaddle - 0.5) * 2
		
		getWhereBallHitLeftPaddle: ->
			paddleTopYPos = @leftPaddle.state.yPos - @ball.config.ballHeight
			paddleBottomYPos = @leftPaddle.state.yPos + @leftPaddle.config.paddleHeight
			return null unless @ball.state.xVelocity < 0
			return null unless @ball.state.xPos < (@leftPaddle.config.paddleXGap + @leftPaddle.config.paddleWidth)
			return null unless paddleTopYPos < @ball.state.yPos < paddleBottomYPos
			
			distanceFromTop = @ball.state.yPos - paddleTopYPos
			paddleHeightWithExtra = paddleBottomYPos - paddleTopYPos
			fractionAlongPaddle = distanceFromTop / paddleHeightWithExtra
			
			# Move the zero-point and size of 0.0...0.5...1.0 to -1.0...0.0...1.0
			return (fractionAlongPaddle - 0.5) * 2
)()