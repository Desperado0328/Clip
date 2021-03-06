# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

# Pong
# Coordinates range from (0, 0) in upper-left corner to (100, 100) in lower-right

$ -> new Pong new LeftPaddle('.left-paddle')
	, new RightPaddle('.right-paddle')
	, new Ball('.ball', GAME_WINDOW_ASPECT_RATIO)
	, new Score('.left-score', 0)
	, new Score('.right-score', 0)
	, new ReturnToMiddleIntelligence
	, new ReturnToMiddleIntelligence

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
	constructor: (@leftPaddle, @rightPaddle, @ball, @leftScore, @rightScore, @leftPaddleAI, @rightPaddleAI) ->
		@config = @getConfig()
		@state = @getState()
		@$gameWindow = $ '.game-window'
		@$window = $ window
		@$document = $ document
		
		@init()
	
	init: ->
		@updateConfig()
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
	
	updateConfig: ->
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
		@leftScore.resize @$gameWindow.height()
		@rightScore.resize @$gameWindow.height()
	
	updateState: ->
		@leftPaddle.updateState()
		@rightPaddle.updateState()
		@ball.updateState()
		@leftScore.updateState()
		@rightScore.updateState()
	
	attachHandlers: ->
		# Modified from: http://stackoverflow.com/a/6011119/770170
		@$document.keydown((e) =>
			switch e.which
				when KEY_CODES.DOWN
					@rightPaddleAI = new KeyboardIntelligence
					@rightPaddle.state.yPos += @rightPaddle.config.initVelocity unless @state.paused
				when KEY_CODES.UP
					@rightPaddleAI = new KeyboardIntelligence
					@rightPaddle.state.yPos -= @rightPaddle.config.initVelocity unless @state.paused
				when KEY_CODES.Z
					@leftPaddleAI = new KeyboardIntelligence
					@leftPaddle.state.yPos += @leftPaddle.config.initVelocity unless @state.paused
				when KEY_CODES.A
					@leftPaddleAI = new KeyboardIntelligence
					@leftPaddle.state.yPos -= @leftPaddle.config.initVelocity unless @state.paused
				when KEY_CODES.P
					if !@state.paused
						@state.paused = true
						clearInterval @state.intervalId
						@state.intervalId = null # invalidate for any future sanity checks
					else
						@state.paused = false
						@play()
			# TODO DRY
			@leftPaddle.state.yPos = 0 if @leftPaddle.state.yPos < 0
			@leftPaddle.state.yPos = 100 - @leftPaddle.config.height if @leftPaddle.state.yPos > 100 - @leftPaddle.config.height
			@rightPaddle.state.yPos = 0 if @rightPaddle.state.yPos < 0
			@rightPaddle.state.yPos = 100 - @rightPaddle.config.height if @rightPaddle.state.yPos > 100 - @rightPaddle.config.height
			
			@updateState()
		)
		
		$(window).resize( =>
			@resizeGameWindow @windowAspectRatio()
		)
	
	play: ->
		@state.intervalId = window.setInterval( =>
			@stepObjects()
			@handleCollisions()
			@updateState()
		, @ball.TIME_STEP)
	
	stepObjects: ->
		@ball.step(@leftPaddle, @rightPaddle)
		@leftPaddleAI.step(@leftPaddle, @ball)
		@rightPaddleAI.step(@rightPaddle, @ball)
	
	handleCollisions: ->
		# If the ball is beyond the bounds of an edge while moving away from it, pull it
		# back in and negate the velocity to simulate a bounce.
		@bounceBallOffEdges()
		@bounceBallOff @leftPaddle
		@bounceBallOff @rightPaddle
	
	bounceBallOffEdges: ->
		if @ball.state.xPos < 0 # left edge
			@ball.state.xPos = 0
			@ball.state.xVelocity *= -1
			@rightScore.add 1
		if @ball.state.xPos > 100 - @ball.config.width # right edge
			@ball.state.xPos = 100 - @ball.config.width
			@ball.state.xVelocity *= -1
			@leftScore.add 1
		if @ball.state.yPos < 0 # top edge
			@ball.state.yPos = 0
			@ball.state.yVelocity *= -1
		if @ball.state.yPos > 100 - @ball.config.height # bottom edge
			@ball.state.yPos = 100 - @ball.config.height
			@ball.state.yVelocity *= -1
	
	bounceBallOff: (paddle) ->
		edge = paddle.getEdgeConditions @ball
		
		whereBallHitPaddle = @getWhereBallHitPaddle paddle, edge.velocityCondition, edge.xCondition
		if whereBallHitPaddle
			@ball.state.xPos = edge.xPos
			@ball.state.xVelocity *= -1
			@ball.state.yVelocity = @ball.config.initYVelocity * whereBallHitPaddle
	
	getWhereBallHitPaddle: (paddle, velocityCondition, xCondition) ->
		paddleTopYPos = paddle.state.yPos - @ball.config.height
		paddleBottomYPos = paddle.state.yPos + paddle.config.height
		yCondition = paddleTopYPos < @ball.state.yPos < paddleBottomYPos
		
		return null unless velocityCondition
		return null unless xCondition
		return null unless yCondition
		
		distanceFromTop = @ball.state.yPos - paddleTopYPos
		paddleHeightWithExtra = paddleBottomYPos - paddleTopYPos
		fractionAlongPaddle = distanceFromTop / paddleHeightWithExtra
		
		# Convert 0..1 to -1..1 (move the halfway point from 0.5 to 0 and then expand)
		return (fractionAlongPaddle - 0.5) * @ball.config.yVelocityMultiplier

class Score
	constructor: (locator, @score) ->
		@$self = $ locator
		@fontSize = .10 # % / 100
	
	updateState: ->
		@$self.text @score
	
	resize: (windowHeight) ->
		@$self.css 'font-size', (windowHeight * @fontSize) + PX
	
	add: (amount) ->
		@score += amount

class ArtificialIntelligence
	constructor: ->
		
	stepAndBounceOffEdges: (paddle) ->
		paddle.state.yPos += paddle.state.yVelocity
		
		if paddle.state.yPos < 0
			paddle.state.yPos = 0
			paddle.state.yVelocity *= -1
		if paddle.state.yPos > (100 - paddle.config.height)
			paddle.state.yPos = 100 - paddle.config.height
			paddle.state.yVelocity *= -1
	
	getMidpoint: (object) ->
		object.state.yPos + (object.config.height / 2)
	
	moveMidpointTowardBall: (paddle, ball) ->
		paddleMidpointY = @getMidpoint paddle
		ballMidpointY = @getMidpoint ball
		if paddleMidpointY < ballMidpointY
			paddle.state.yVelocity = Math.abs(paddle.state.yVelocity)
		else
			paddle.state.yVelocity = Math.abs(paddle.state.yVelocity) * -1

class BackAndForthIntelligence extends ArtificialIntelligence
	constructor: ->
		
	
	step: (paddle, ball=null) ->
		@stepAndBounceOffEdges paddle

class FollowBallIntelligence extends ArtificialIntelligence
	constructor: ->
		
	
	step: (paddle, ball) ->
		@moveMidpointTowardBall paddle, ball
		@stepAndBounceOffEdges paddle

class ReturnToMiddleIntelligence extends ArtificialIntelligence
	constructor: ->
		
	
	step: (paddle, ball) ->
		if paddle.getEdgeConditions(ball).velocityCondition
			@moveMidpointTowardBall paddle, ball
		else
			if @getMidpoint(paddle) < 50
				paddle.state.yVelocity = Math.abs(paddle.state.yVelocity)
			else
				paddle.state.yVelocity = Math.abs(paddle.state.yVelocity) * -1
		@stepAndBounceOffEdges paddle
		
class KeyboardIntelligence extends ArtificialIntelligence
	constructor: ->
		
	
	step: (paddle, ball=null) ->
		# no op (allow keyboard to control the paddle)

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
			yPos: 50 - (@config.height / 2) # % (the exact center)
			yVelocity: 0.05 * @TIME_STEP # % per time step
	
	updateState: ->
		@$self.css 'top', @state.yPos + PERCENT

class LeftPaddle extends Paddle
	constructor: (locator, artificialIntelligence) ->
		super locator
	
	getEdgeConditions: (ball) ->
		velocityCondition = ball.state.xVelocity < 0
		edgeXPos = @config.xGap + @config.width
		crossedTheEdge = ball.state.xPos < edgeXPos
		crossedTheEdgeLastStep = edgeXPos - ball.state.xPos <= Math.abs(ball.state.xVelocity)
		
		# return
		velocityCondition: velocityCondition
		xPos: edgeXPos
		xCondition: crossedTheEdge && crossedTheEdgeLastStep

class RightPaddle extends Paddle
	constructor: (locator) ->
		super locator
	
	getEdgeConditions: (ball) ->
		velocityCondition = ball.state.xVelocity > 0
		edgeXPos = 100 - @config.xGap - @config.width - ball.config.width
		crossedTheEdge = ball.state.xPos > edgeXPos
		crossedTheEdgeLastStep = ball.state.xPos - edgeXPos <= ball.state.xVelocity
		
		# return
		velocityCondition: velocityCondition
		xPos: edgeXPos
		xCondition: crossedTheEdge && crossedTheEdgeLastStep

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
			initYVelocity: 0.1 * @TIME_STEP # % per time step
			yVelocityMultiplier: 3
		
		@state =
			xPos: 50 - (@config.width / 2) # % (the exact center)
			yPos: 50 - (@config.height / 2) # % (the exact center)
			xVelocity: @config.initYVelocity / 2
			yVelocity: @config.initYVelocity
	
	resize: ->
		@$self.css 'width', @config.width + PERCENT
		@$self.css 'height', @config.height + PERCENT
	
	updateState: ->
		@$self.css 'left', @state.xPos + PERCENT
		@$self.css 'top', @state.yPos + PERCENT
	
	step: (leftPaddle, rightPaddle) ->
		@state.xPos += @state.xVelocity
		@state.yPos += @state.yVelocity