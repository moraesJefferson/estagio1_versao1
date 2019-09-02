-- FILE: scene_menu.lua 
-- DESCRIPTION: start the menu and allow sound on/off

local composer = require( "composer" )

local scene = composer.newScene()

local widget = require "widget"
widget.setTheme( "widget_theme_android_holo_light" )

-- -----------------------------------------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE unless "composer.removeScene()" is called.
-- -----------------------------------------------------------------------------------------------------------------

-- local forward references should go here
local btn_play,btn_exit,btn_sounds
local moveOrc, moveNaoki,moveCannon

user = loadsave.loadTable("user.json")

local function onPlayTouch(event)
    if(event.phase == "ended") then 
        audio.play(_CLICK)
        composer.gotoScene("cena1", "slideLeft")
    end
end

local function onExitTouch(event)
    if(event.phase == "ended") then 
        audio.play(_CLICK)
        os.exit();
        --composer.gotoScene("scene_upgrades", "slideUp")
    end
end

local function onSoundsTouch(event)
    if(event.phase == "ended") then 
        if(user.playsound == true) then 
            -- mute the game
            audio.setVolume(0)
            btn_sounds.alpha = 0.5
            user.playsound = false
        else 
            -- unmute the game
            audio.setVolume(1)
            btn_sounds.alpha = 1
            user.playsound = true
        end
        loadsave.saveTable(user, "user.json")
    end
end
-- -------------------------------------------------------------------------------

-- "scene:create()"
function scene:create( event )

    local sceneGroup = self.view

    -- Initialize the scene here.
    -- Example: add display objects to "sceneGroup", add touch listeners, etc.
    local background = display.newImageRect(sceneGroup, "image/menu/menu2.png", 1425, 930)
        background.x = _CX; background.y = _CY;

   -- local gameTitle = display.newImageRect(sceneGroup, "image/menu/title.png", 508, 210)
       -- gameTitle.x = _CX; gameTitle.y = _CH * 0.2

    local naoki = display.newImageRect(sceneGroup, "image/menu/naoki.png", 140, 100)
        naoki.x = _L - naoki.width; naoki.y = _CH * 0.925;

    local orc = display.newImageRect(sceneGroup, "image/menu/orc.png", 80, 100)
        orc.x = _R + orc.width; orc.y = _CH * 0.925;

    local cannon = display.newImageRect(sceneGroup, "image/menu/cannon.png", 100, 70)
        cannon.x = _R + cannon.width; cannon.y = _CH * 0.945;

    --local torre = display.newImageRect(sceneGroup,"image/menu/torre.png",150,600)
    --torre.x = _R * 0.925; torre.y = _CY * 1.25;

    -- Create some buttons
    btn_play = widget.newButton {
        width = 200,
        height = 55,
        defaultFile = "image/menu/start.png",
        overFile = "image/menu/start.png",
        onEvent = onPlayTouch
    }
    btn_play.x = _R * 0.75
    btn_play.y = _B * 0.75
    sceneGroup:insert(btn_play)

    btn_exit = widget.newButton {
        width = 200,
        height = 50,
        defaultFile = "image/menu/exit.png",
        overFile = "image/menu/exit.png",
        onEvent = onExitTouch
    }
    btn_exit.x = _R * 0.75
    btn_exit.y = _B * 0.85
    sceneGroup:insert(btn_exit)

    btn_sounds = widget.newButton {
        width = 49,
        height = 49,
        defaultFile = "image/menu/sound.png",
        overFile = "image/menu/sound.png",
        onEvent = onSoundsTouch
    }
    btn_sounds.x = _R * 0.95
    btn_sounds.y = _B * 0.075
    sceneGroup:insert(btn_sounds)

    -- Transitions
    moveNaoki = transition.to(naoki, {x=_CX, delay=250})
    moveOrc = transition.to(orc, {x=55, delay=250})
    moveCannon = transition.to(cannon, {x=150, delay=250})

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