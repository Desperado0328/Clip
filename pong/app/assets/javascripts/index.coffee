# Pong
# (0, 0) coordinates located in upper-left corner of game window, (100, 100) in lower-right

;(-> # TODO Is this unnecessary in CoffeeScript?
	$ -> new Pong new LeftPaddle('.paddle.left'), new RightPaddle('.paddle.right'), new Ball('.ball', GAME_WINDOW_ASPECT_RATIO)
	
	# TODO Don't make these global
	GAME_WINDOW_ASPECT_RATIO = 3 / 2 # width / height
	PERCENT = '%' # CSS
	PX = 'px'
	KEY_CODES = # http://www.cambiaresearch.com/articles/15/javascript-char-codes-key-codes
		UP: 38
		DOWN: 40
		P: 80
		A: 65
		Z: 90
	
	class Pong
		constructor: (@leftPaddle, @rightPaddle, @ball) ->
			@config = @getConfig()
			@state = @getState()
			@$gameWindow = $ '.game-window'
			@$window = $ window
			@$document = $ document
			
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
			
			@leftPaddle.$self.css 'width', @leftPaddle.config.width + PERCENT
			@leftPaddle.$self.css 'height', @leftPaddle.config.height + PERCENT
			@leftPaddle.$self.css 'left', @leftPaddle.config.xGap + PERCENT
			
			@rightPaddle.$self.css 'width', @rightPaddle.config.width + PERCENT
			@rightPaddle.$self.css 'height', @rightPaddle.config.height + PERCENT
			@rightPaddle.$self.css 'right', @rightPaddle.config.xGap + PERCENT
		
		windowAspectRatio: ->
			@$window.width() / @$window.height()
		
		resizeGameWindow: (windowAspectRatio) ->
			if @config.aspectRatio < windowAspectRatio
				# maximize height because there isn't much height to work with
				@$gameWindow.css 'height', (@config.longestSide * @$window.height()) + PX
				@$gameWindow.css 'width', @$gameWindow.height() * @config.aspectRatio + PX
			else
				# maximize width because there isn't much width to work with
				@$gameWindow.css 'width', (@config.longestSide * @$window.width()) + PX
				@$gameWindow.css 'height', @$gameWindow.width() / @config.aspectRatio + PX
			
			@ball.resize()
		
		updateState: ->
			@leftPaddle.$self.css 'top', @leftPaddle.state.yPos + PERCENT
			@rightPaddle.$self.css 'top', @rightPaddle.state.yPos + PERCENT
			@ball.$self.css 'left', @ball.state.xPos + PERCENT
			@ball.$self.css 'top', @ball.state.yPos + PERCENT
		
		attachHandlers: ->
			# Modified from: http://stackoverflow.com/a/6011119/770170
			@$document.keydown((e) =>
				switch e.which
					when KEY_CODES.DOWN
						@rightPaddle.state.yPos += @rightPaddle.config.initVelocity unless @state.paused
					when KEY_CODES.UP
						@rightPaddle.state.yPos -= @rightPaddle.config.initVelocity unless @state.paused
					when KEY_CODES.Z
						@leftPaddle.state.yPos += @leftPaddle.config.initVelocity unless @state.paused
					when KEY_CODES.A
						@leftPaddle.state.yPos -= @leftPaddle.config.initVelocity unless @state.paused
					when KEY_CODES.P
						if !@state.paused
							@state.paused = true
							clearInterval @state.intervalId
							@state.intervalId = null # invalidate for any future sanity checks
						else
							@state.paused = false
							@play()
				@rightPaddle.state.yPos = 0 if @rightPaddle.state.yPos < 0
				@rightPaddle.state.yPos = 100 - @rightPaddle.config.height if @rightPaddle.state.yPos > 100 - @rightPaddle.config.height
				@updateState()
			)
			
			$(window).resize( =>
				@resizeGameWindow @windowAspectRatio()
			)
		
		play: ->
			@state.intervalId = window.setInterval( =>
				@ball.step(@leftPaddle, @rightPaddle)
				@leftPaddle.stepAI()
				@updateState()
			, @ball.TIME_STEP)
	
	class Animatable
		constructor: ->
			@TIME_STEP = 20 # milliseconds
	
	class Paddle extends Animatable
		constructor: (locator) ->
			super()
			
			@$self = $ locator
			
			# TODO Make this a static property (see http://arcturo.github.com/library/coffeescript/03_classes.html)
			@config =
				width: 3 # %
				height: 20 # %
				xGap: 10 # %
				initVelocity: 5 # % per keypress
			
			@state =
				yPos: 0 # %
				yVelocity: 0.05 * @TIME_STEP # % per time step
		
		stepAI: ->
			@state.yPos += @state.yVelocity
			if @state.yPos < 0
				@state.yPos = 0
				@state.yVelocity *= -1
			if @state.yPos > (100 - @config.height)
				@state.yPos = 100 - @config.height
				@state.yVelocity *= -1
	
	class LeftPaddle extends Paddle
		constructor: (locator) ->
			super locator
			@isRight = false
	
	class RightPaddle extends Paddle
		constructor: (locator) ->
			super locator
			@isRight = true
	
	class Ball extends Animatable
		constructor: (locator, gameWindowAspectRatio) ->
			super()
			
			@$self = $ locator
			
			width = 4 # % (and em for border-radius)	
			# The ball aspect ratio is the inverse of the game window aspect ratio, canceling
			# it out and resulting in a 1:1 aspect ratio (a square ball).
			height = width * gameWindowAspectRatio # %
			@config =
				width: width
				height: height
				initVelocity: 0.06 * @TIME_STEP # % per time step
			
			@state =
				yPos: 50 # %
				xPos: 50 # %
				xVelocity: 0.02 * @TIME_STEP # % per time step
				yVelocity: 0.06 * @TIME_STEP # % per time step
		
		resize: ->
			@$self.css 'width', @config.width + PERCENT
			@$self.css 'height', @config.height + PERCENT
		
		step: (leftPaddle, rightPaddle) ->
			@state.xPos += @state.xVelocity
			@state.yPos += @state.yVelocity
			@bounceOffEdges()
			@bounceOffOf leftPaddle
			@bounceOffOf rightPaddle
		
		bounceOffEdges: ->
			# If the ball is beyond the bounds of the game window, pull it back in and negate
			# the velocity to simulate a bounce.
			if @state.xPos < 0
				@state.xPos = 0
				@state.xVelocity *= -1
			if @state.xPos > 100 - @config.width
				@state.xPos = 100 - @config.width
				@state.xVelocity *= -1
			if @state.yPos < 0
				@state.yPos = 0
				@state.yVelocity *= -1
			if @state.yPos > 100 - @config.height
				@state.yPos = 100 - @config.height
				@state.yVelocity *= -1
		
		bounceOffOf: (paddle) ->
			# If the ball is beyond the bounds of the game window, pull it back in and negate
			# the velocity to simulate a bounce.
			
			if paddle.isRight
				velocityCondition = @state.xVelocity > 0
				xPos = 100 - paddle.config.xGap - paddle.config.width - @config.width
				xCondition = @state.xPos > xPos
			else
				velocityCondition = @state.xVelocity < 0
				xPos = paddle.config.xGap + paddle.config.width
				xCondition = @state.xPos < xPos
			
			whereBallHitPaddle = @getWhereBallHitPaddle paddle, velocityCondition, xCondition
			if whereBallHitPaddle
				@state.xPos = xPos
				@state.xVelocity *= -1
				@state.yVelocity = @config.initVelocity * whereBallHitPaddle
		
		getWhereBallHitPaddle: (paddle, velocityCondition, xCondition) ->
			paddleTopYPos = paddle.state.yPos - @config.height
			paddleBottomYPos = paddle.state.yPos + paddle.config.height
			yCondition = paddleTopYPos < @state.yPos < paddleBottomYPos
			
			return null unless velocityCondition
			return null unless xCondition
			return null unless yCondition
			
			distanceFromTop = @state.yPos - paddleTopYPos
			paddleHeightWithExtra = paddleBottomYPos - paddleTopYPos
			fractionAlongPaddle = distanceFromTop / paddleHeightWithExtra
			
			# Move the zero-point and size of 0.0...0.5...1.0 to -1.0...0.0...1.0
			return (fractionAlongPaddle - 0.5) * 2
)()