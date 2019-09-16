local _M = {}

--local eachframe = require('libs.eachframe')
--local newPuff = require('classes.puff').newPuff


function _M.newNaoki()

	local playerSheetData = {width=100, height=74, numFrames=9, sheetContentWidth=900, sheetContentHeight=74}
	local playerSheet = graphics.newImageSheet("image/spriteSheet/arqueiro.png", playerSheetData)
	local playerSequenceData = {
    {name="shooting", start=1, count=9, time=1000, loopCount=0, loopDirection = "foward"}
	}

	local sheetOptionsStop = { width = 100, height = 74, numFrames = 4, sheetContentWidth=400, sheetContentHeight=74 }

	local sheetStop = graphics.newImageSheet( "image/spriteSheet/parado.png", sheetOptionsStop )

	local sequenceStop = {
		{
			name = "normalStop",
			start = 1,
			count = 4,
			time = 1000,
			loopCount = 0,
			loopDirection = "forward"
		}
	}

	local player, waiting

	local bullets = {} -- table that will hold the bullet objects
	local bulletCounter = 0 -- number of bullets shot
	local bulletTransition = {} -- table to hold bullet transitions
	local bulletTransitionCounter = 0 -- number of bullet transitions made


	local function stop()
		player.isVisible = false;
		waiting.isVisible = true;
		waiting:setSequence( "normalStop" )
		waiting:play()  
	end

	local function shoot()
		bulletCounter = bulletCounter + 1
			bullets[bulletCounter] = display.newImageRect(sceneGroup, "image/spriteSheet/Arrow.png", 54, 54)
			bullets[bulletCounter].x = player.x - (player.width * 0.5)
			bullets[bulletCounter].y = player.y
			bullets[bulletCounter].id = "bullet"
			physics.addBody(bullets[bulletCounter])
			bullets[bulletCounter].isSensor = true 

			bulletTransition[bulletCounter] = transition.to(bullets[bulletCounter], {x=-250, time=2000, onComplete=function(self)
			if(self~=nil) then 
				display.remove(self)
			end
			end})

			player:setSequence("shooting")
			player:play()
			audio.play(_THROW)
			stop()
	end

	local function playerShoot( event )
		if(event.phase == "began") then
			waiting.isVisible = false;
			player.isVisible = true;
			timer.performWithDelay(700, shoot)
		end
	end
    
    player = display.newSprite(playerSheet, playerSequenceData)
          
    player.x = _CX / 0.67
    player.y = _CY / 0.8
    player.id = "player_shoot"
    player.xScale = 1.3
	player.yScale = 1.3
	player.anchorX = 0.25
    sceneGroup:insert(player)
    physics.addBody(player)
    player:play()
    player.isVisible = false;


    waiting = display.newSprite( sheetStop, sequenceStop )

    waiting.x = _CX / 0.67
    waiting.y = _CY / 0.8
    waiting.id = "player_stop"
    waiting.xScale = 1.3
	waiting.yScale = 1.3
	waiting.anchorX = 0.25
    sceneGroup:insert(waiting)
    waiting:play()
    waiting.isVisible = true;

    waiting:addEventListener("touch", playerShoot)
    

------------------------------------------------------------------------------------------------------------------------


	-- Cannon force is set by a player by moving the finger away from the cannon
	cannon.force = 0
	cannon.forceRadius = 0
	-- Increments are for gamepad control
	cannon.radiusIncrement = 0
	cannon.rotationIncrement = 0
	-- Minimum and maximum radius of the force circle indicator
	local radiusMin, radiusMax = 64, 200


	local trajectoryPoints = {} -- White dots along the flying path of a ball
	local balls = {} -- Container for the ammo


	-- Launch loaded cannon ball
	function cannon:fire()
		if self.ball and not self.ball.isLaunched then
			self.ball:launch(self.rotation, self.force)
			self:removeTrajectoryPoints()
			self.launchTime = system.getTimer() -- This time value is needed for the trajectory points
			self.lastTrajectoryPointTime = self.launchTime
			newPuff({g = self.parent, x = self.x, y = self.y, isExplosion = true}) -- Display an explosion visual effect
			map:snapCameraTo(self.ball)
			sounds.play('cannon')
		end
	end

	function cannon:setForce(radius, rotation)
		self.rotation = rotation % 360
		if radius > radiusMin then
			if radius > radiusMax then
				radius = radiusMax
			end
			self.force = radius
		else
			self.force = 0
		end
		
		return math.min(radius, radiusMax), self.rotation
	end

	function cannon:engageForce()
		forceArea.isVisible = false
		self.forceRadius = 0
		if self.force > 0 then
			self:fire()
		end
	end

	function cannon:touch(event)
		if event.phase == 'began' then
			display.getCurrentStage():setFocus(self, event.id)
			self.isFocused = true
		elseif self.isFocused then
			if event.phase == 'moved' then
				local x, y = self.parent:contentToLocal(event.x, event.y)
				x, y = x - self.x, y - self.y
				local rotation = math.atan2(y, x) * 180 / math.pi + 180
				local radius = math.sqrt(x ^ 2 + y ^ 2)
				self:setForce(radius, rotation)
			else
				--display.getCurrentStage():setFocus(self, nil)
				--self.isFocused = false
				--self:engageForce()
			end
		end
		return true
	end
	waiting:addEventListener('touch')
	
	-- eachframe.add(waiting)

	-- -- finalize() is called by Corona when display object is destroyed
	-- function cannon:finalize()
	-- 	eachframe.remove(self)
	-- end
	-- cannon:addEventListener('finalize')

	cannon:prepareAmmo()

	return naoki
end