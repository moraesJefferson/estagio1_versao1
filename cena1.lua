-- File: scene_game.lua
-- Description: allow the player to play the game

local composer = require( "composer" )

local scene = composer.newScene()

local widget = require "widget"
widget.setTheme( "widget_theme_android_holo_light" )

local physics = require "physics"
physics.start()
physics.setGravity(0,0)


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
 
-- -----------------------------------------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE unless "composer.removeScene()" is called.
-- -----------------------------------------------------------------------------------------------------------------

-- local forward references should go here
local player, waiting
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

    local background = display.newImageRect(sceneGroup, "image/cenarios/cena1.png", 1425, 925)
        background.x = _CX
        background.y = _CY

    local castelo = display.newImageRect(sceneGroup, "image/cenarios/castelo.png", 600, 400)
        castelo.x = _R * 0.9
        castelo.y = _B * 0.7

    player = display.newSprite(playerSheet, playerSequenceData)
          
    player.x = _CX / 0.625
    player.y = _CY / 0.75
    player.id = "player_shoot"
    sceneGroup:insert(player)
    physics.addBody(player)
    player:play()
    player.isVisible = false;


    waiting = display.newSprite( sheetStop, sequenceStop )

    waiting.x = _CX / 0.625
    waiting.y = _CY / 0.75
    waiting.id = "player_stop"
    sceneGroup:insert(waiting)
    waiting:play()
    waiting.isVisible = true;

    waiting:addEventListener("touch", playerShoot)
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