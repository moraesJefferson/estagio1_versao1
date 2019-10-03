-- File: scene_game.lua
-- Description: allow the player to play the game

local composer = require( "composer" )
local scene = composer.newScene()


local widget = require "widget"
widget.setTheme( "widget_theme_android_holo_light" )

local physics = require "physics"
physics.start()
physics.setGravity(0,30)
physics.setDrawMode( "normal" )


local playerSheetData = {width=100, height=74, numFrames=13, sheetContentWidth=1300, sheetContentHeight=74}
local playerSheet = graphics.newImageSheet("image/spriteSheet/naoki_sprite2.png", playerSheetData)
local playerSequenceData = {
    {name="shooting", start=1, count=9, time=700, loopCount=1},
    {name="stop", start=10, count=4, time=1000, loopCount=0}
}

local orcSheetData = {width=84, height=81, numFrames=7, sheetContentWidth=588, sheetContentHeight=81}
local orcSheet1 = graphics.newImageSheet("image/spriteSheet/orc1_attack.png", orcSheetData)
--local pirateSheet2 = graphics.newImageSheet("images/characters/pirate2.png", pirateSheetData)
--local pirateSheet3 = graphics.newImageSheet("images/characters/pirate3.png", pirateSheetData)
local orcSequenceData = {
    {name="attack", start=1, count=7, time=575, loopCount=0}
}
 
-- -----------------------------------------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE unless "composer.removeScene()" is called.
-- -----------------------------------------------------------------------------------------------------------------

-- local forward references should go here

-- Create display group for predicted trajectory
local evento
local teste
local line
local predictedPath = display.newGroup()
predictedPath.alpha = 0.2

local intialForceMultiplier = 1 --MOD
local perFrameDelta = 1.005  --MOD
local forceMultiplier = intialForceMultiplier  --MOD
local lastEvent  --MOD

-- Create function forward references
local getTrajectoryPoint
local launchProjectile

local lane = {}

local player, waiting
local enemy = {} -- table to hold enemy objects
local enemyCounter = 0 -- number of enemies sent
local enemySendSpeed = 250 -- how often to send the enemies
local enemyTravelSpeed = 10000 -- how fast enemies travel across the scree
local enemyIncrementSpeed = 1.5 -- how much to increase the enemy speed
local enemyMaxSendSpeed = 20 -- max send speed, if this is not set, the enemies could just be one big flood 

local poof = {}
local poofCounter = 0

local timeCounter = 0 -- how much time has passed in the game
local pauseGame = false -- is the game paused?
local pauseBackground, btn_pause, pauseText, pause_returnToMenu, pauseReminder -- forward declares

local bullets = {} -- table that will hold the bullet objects
local bulletCounter = 0 -- number of bullets shot
local bulletTransition = {} -- table to hold bullet transitions
local bulletTransitionCounter = 0 -- number of bullet transitions made

local onGameOver, gameOverBox, gameoverBackground, btn_returnToMenu -- forward declare

-- -------------------------------------------------------------------------------


-- "scene:create()"
function scene:create( event )

    local sceneGroup = self.view


    -- Initialize the scene here.
    -- Example: add display objects to "sceneGroup", add touch listeners, etc.
    local function returnToMenu(event)
        if(event.phase == "ended") then 
            audio.play(_CLICK)
            composer.gotoScene("scene_menu", "slideRight")
        end 
    end

    local function stop()
        player:setSequence("stop")
        player:play() 
    end

    local function sendEnemies()
        -- timeCounter : keeps track of the time in the game, starts at 0
        -- enemySendSpeed : will tell us how often to send the enemies, starts at 75
        -- enemyCounter : keeps track of the number of enemies on the screen, starts at 0
        -- enemyIncrementSpeed : how much to increase the enemy speed, starts at 1.5
        -- enemyMaxSendSpeed : limit the send speed to 20, starts at 20

        -- In math terms, Modulo (%) will return the remainder of a division. 10%2=0, 11%2=1, 14%5=4, 19%8=3
        timeCounter = timeCounter + 1
        if((timeCounter%enemySendSpeed) == 0) then 
            enemyCounter = enemyCounter + 1
            enemySendSpeed = enemySendSpeed - enemyIncrementSpeed
            if(enemySendSpeed <= enemyMaxSendSpeed) then 
                enemySendSpeed = enemyMaxSendSpeed
            end

            --local temp = math.random(1,3)
            --if(temp == 1) then 
                enemy[enemyCounter] = display.newSprite(orcSheet1, orcSequenceData)
            --elseif(temp == 2) then 
               --- enemy[enemyCounter] = display.newSprite(pirateSheet2, pirateSequenceData)
            --else 
               -- enemy[enemyCounter] = display.newSprite(pirateSheet3, pirateSequenceData)
            --end

            enemy[enemyCounter].x = _L - 50
            enemy[enemyCounter].y = lane[1].y
            enemy[enemyCounter].id = "enemy"
            enemy[enemyCounter].xScale = 3
            enemy[enemyCounter].yScale = 3
            physics.addBody(enemy[enemyCounter],'static',{density = 20})
            enemy[enemyCounter].isFixedRotation = true 
            sceneGroup:insert(enemy[enemyCounter])            

            transition.to(enemy[enemyCounter], {x=_R+50, time=enemyTravelSpeed, onComplete=function(self) 
                    if(self~=nil) then display.remove(self); end 
                end})

            enemy[enemyCounter]:setSequence("attack")
            enemy[enemyCounter]:play()
        end
    end

    local background = display.newImageRect(sceneGroup, "image/cenarios/cena1_full.png", 1920, 1080)
        background.x = _CX
        background.y = _CY
        background.xScale = 2
        background.yScale = 2

    for i=1,1 do 
        lane[i] = display.newImageRect(sceneGroup, "image/cenarios/road.png", 3600, 100)
        lane[i].x = _CX * 0.775
        if(i==1) then
            lane[i].y = _B * 0.884
       -- else
           -- lane[i].y = _B - 150
        end
        lane[i].id = i
    end 
    
    local castelo = display.newImageRect(sceneGroup, "image/cenarios/castelo.png", 800, 700)
        castelo.x = _R * 0.9
        castelo.y = _B * 0.63
        castelo.xScale = 2
        castelo.yScale = 2

    player = display.newSprite(playerSheet, playerSequenceData)     
    player.x = _CX / 0.37
    player.y = _CY / 0.82
    player.force = 0
    player.id = "player_shoot"
    player.xScale = 2.5
    player.yScale = 2.5
    sceneGroup:insert(player)
    physics.addBody(player,'static')
    player:setSequence("stop")
    player:play()
    player.isVisible = true;

    getTrajectoryPoint = function( startingPosition, startingVelocity, n )
 
        -- Velocity and gravity are given per second but we want time step values
        local t = 1/display.fps  -- Seconds per time step at 60 frames-per-second (default)
        local stepVelocity = { x=t*startingVelocity.x, y=t*startingVelocity.y }
        local gx, gy = physics.getGravity()
        local stepGravity = { x=t*0, y=t*gy }
        return {
            x = startingPosition.x  + n * stepVelocity.x + 0.25 * (n*n+n) * stepGravity.x,
            y = startingPosition.y + n * stepVelocity.y + 0.25 * (n*n+n) * stepGravity.y
        }
    end

    local function updatePrediction(event)
        lastEvent = event

        display.remove( predictedPath )
        predictedPath = display.newGroup()
        predictedPath.alpha = 0.2
 
        local startingVelocity = { x=player.x-event.xStart, y=player.y-event.yStart }

        startingVelocity.x = startingVelocity.x * forceMultiplier --MOD
        startingVelocity.y = startingVelocity.y * forceMultiplier --MOD

        -- for i = 1,-240,-1 do
        --     local s = { x=event.xStart, y=event.yStart }
        --     local trajectoryPosition = getTrajectoryPoint( s, startingVelocity, i )
        --     local dot = display.newCircle( predictedPath, trajectoryPosition.x, trajectoryPosition.y, 6 )
        -- end
    end

    local function onCollision(event)

        local function removeOnEnemyHit(obj1, obj2)
            display.remove(obj1)
            display.remove(obj2)
            --if(obj1.id == "enemy") then 
               -- enemyHit(event.object1.x, event.object1.y)
            --else
               -- enemyHit(event.object2.x, event.object2.y)
            --end
        end

        local function showPlayerHit()
            player:setSequence("hurt")
            player:play()
            player.alpha = 0.5
            local tmr_onPlayerHit = timer.performWithDelay(100, playerHit, 1)
        end

        local function removeOnPlayerHit(obj1, obj2)
            if(obj1 ~= nil and obj1.id == "enemy") then 
                display.remove(obj1)
            end
            if(obj2 ~= nil and obj2.id == "enemy") then 
                display.remove(obj2)
            end
        end

        if( (event.object1.id == "bullet" and event.object2.id == "enemy") or (event.object1.id == "enemy" and event.object2.id == "bullet")  ) then 
            removeOnEnemyHit(event.object1, event.object2)
        elseif(event.object1.id == "enemy" and event.object2.id == "player") then 
            --showPlayerHit()
            removeOnPlayerHit(event.object1, nil)
        elseif(event.object1.id == "player" and event.object2.id == "enemy") then 
            --showPlayerHit()
            removeOnPlayerHit(nil, event.object2)
        end

    end


    local function shoot(event)
        audio.play(_THROW)

        bulletCounter = bulletCounter + 1
        bullets[bulletCounter] = display.newImageRect(sceneGroup, "image/spriteSheet/Arrow.png", 54, 54)
        bullets[bulletCounter].x = player.x  
        bullets[bulletCounter].y = player.y
        bullets[bulletCounter].id = "bullet"
        physics.addBody(bullets[bulletCounter],{density = 10.0, bounce = 0.2, radius=4})
        bullets[bulletCounter].isSensor = true
        local vx, vy = (event.x-event.xStart)*-1, (event.y-event.yStart)*-1
        bullets[bulletCounter].rotation = (math.atan2(vy*-1, vx *-1) * 180 / math.pi)
        bullets[bulletCounter]:setLinearVelocity( vx * forceMultiplier ,vy * forceMultiplier )
        bullets[bulletCounter].angularVelocity = -40
        bullets[bulletCounter].gravityScale = 2


        if(self~=nil) then 
            display.remove(self)
        end
    end

    
    local function enterFrame( )
        forceMultiplier = forceMultiplier * perFrameDelta
        if( lastEvent ) then
            updatePrediction(lastEvent)
        end
    end

    local function playerShoot( event )
        evento = event
            local eventX, eventY = event.x, event.y
           
                if ( event.phase == "began" ) then
                    forceMultiplier = intialForceMultiplier --MOD
                    Runtime:addEventListener( "enterFrame", enterFrame ) --MOD
                    line = display.newLine( eventX, eventY, eventX, eventY )
                    line.strokeWidth = 4 ; line.alpha = 0.6  --MOD
                elseif(event.phase == "moved") then
                    display.remove( line )
                    line = display.newLine( event.xStart, event.yStart, eventX, eventY )
                    line.strokeWidth = 4 ; line.alpha = 0.6 --MOD
                    updatePrediction( event )
                else 
                    display.remove( line )
                    updatePrediction( event )
                    player:setSequence("shooting")
                    player:play()
                    Runtime:removeEventListener( "enterFrame", enterFrame )   
                end
            
        return true
    end
    
    local function spriteListener( event )
        if(event.phase == "ended" and event.target.sequence == "shooting" ) then
            stop()
        elseif (player.frame == 8 and event.target.sequence == "shooting" ) then
            shoot(evento)
        end  
    end

    -- Add sprite listener
    player:addEventListener( "sprite", spriteListener )
    Runtime:addEventListener("touch", playerShoot)
    Runtime:addEventListener("enterFrame", sendEnemies)
    Runtime:addEventListener( "collision", onCollision )
end



-- "scene:show()"
function scene:show( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Called when the scene is still off screen (but is about to come on screen).
    elseif ( phase == "did" ) then
        -- Called when the scene is now on screen.
        -- Insert code here to make the scene come alive.
        -- Example: start timers, begin animation, play audio, etc.        
    end

end


-- "scene:hide()"
function scene:hide( event )

    local sceneGroup = self.view
    local phase = event.phase

    if ( phase == "will" ) then
        -- Called when the scene is on screen (but is about to go off screen).
        -- Insert code here to "pause" the scene.
        -- Example: stop timers, stop animation, stop audio, etc.
    elseif ( phase == "did" ) then
        -- Called immediately after scene goes off screen.
    end
end


-- "scene:destroy()"
function scene:destroy( event )

    local sceneGroup = self.view

    -- Called prior to the removal of scene's view ("sceneGroup").
    -- Insert code here to clean up the scene.
    -- Example: remove display objects, save state, etc.
end


-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -------------------------------------------------------------------------------

return scene