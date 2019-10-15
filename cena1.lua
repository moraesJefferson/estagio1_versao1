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

local castleSheetData = {width=1427, height=1129, numFrames=3, sheetContentWidth=4281, sheetContentHeight=1129}
local castleSheet = graphics.newImageSheet("image/spriteSheet/castle1_sprite2.png", castleSheetData)
local castleSequenceData = {
    {name="complete", start=1, count=1, time=100, loopCount=0},
    {name="on_attack", start=2, count=1, time=1000, loopCount=0},
    {name="destroy", start=3, count=1, time=1000, loopCount=0}
}

local orcSheetData = {width=77, height=61, numFrames=13, sheetContentWidth=1001, sheetContentHeight=61}
local orcSheet1 = graphics.newImageSheet("image/spriteSheet/orc1_sprite.png", orcSheetData)
--local pirateSheet2 = graphics.newImageSheet("images/characters/pirate2.png", pirateSheetData)
--local pirateSheet3 = graphics.newImageSheet("images/characters/pirate3.png", pirateSheetData)
local orcSequenceData = {
    {name="attack", start=1, count=7, time=575, loopCount=0},
    {name="run", start=8, count=5, time=575, loopCount=0}
}

local poofSheetData = {width=165, height=180, numFrames=5, sheetContentWidth=825, sheetContentHeight=180}
local poofSheet = graphics.newImageSheet("image/spriteSheet/poof.png", poofSheetData)
local poofSequenceData = {
    {name="puff", start=1, count=5, time=1000, loopCount=2}
}

local collisionSheetData = {width=165, height=180, numFrames=6, sheetContentWidth=990, sheetContentHeight=180}
local collisionSheet = graphics.newImageSheet("image/spriteSheet/puff_collision.png", collisionSheetData)
local collisionSequenceData = {
    {name="puff_collision", start=1, count=6, time=1000, loopCount=2}
}
-- -----------------------------------------------------------------------------------------------------------------
-- All code outside of the listener functions will only be executed ONCE unless "composer.removeScene()" is called.
-- -----------------------------------------------------------------------------------------------------------------

-- local forward references should go here

-- Create display group for predicted trajectory
local T
local evento
local teste = false
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

local player, waiting, castelo,textArrow
local castleLife,healthBar,damageBar,nameBar,lifeBar,myText,life,circle
local enemy = {} -- table to hold enemy objects
local enemyCounter = 0 -- number of enemies sent
local enemySendSpeed = 600 -- how often to send the enemies
local enemyTravelSpeed = 10000 -- how fast enemies travel across the scree
local enemyIncrementSpeed = 1.5 -- how much to increase the enemy speed
local enemyMaxSendSpeed = 20 -- max send speed, if this is not set, the enemies could just be one big flood 

local poof = {}
local poofCounter = 0
local poof_collision = {}

local temp
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
            user.exitMenu = true
	        loadsave.saveTable(user, "user.json")
            composer.gotoScene("scene_menu", "slideRight")
        end 
    end

    local function restartGame(event)
        if(event.phase == "ended") then 
            audio.play(_CLICK)
            user.continue = user.continue - 1
            user.arrowQtd = user.arrowDefault * user.arrowQtdLevel
            loadsave.saveTable(user, "user.json")
            composer.removeScene( "cena1",false )
            composer.gotoScene("cena1", "slideRight")
        end
    end

    local function verificaTotalDeFlechas(event)
        if(user.arrowQtd == 0) then
            if(castelo.isVisible == true) then
                display.remove(castelo)
            elseif(castelo2.isVisible == true) then
                display.remove(castelo2)
            end
            display.remove(player)
            display.remove(healthBar)
            display.remove(damageBar)
            display.remove(nameBar)
            display.remove(myText)
            display.remove(life)
            display.remove(lifeBar)
            display.remove(circle)

            onGameOver()
        end
    end
    local background = display.newImageRect(sceneGroup, "image/cenarios/cena1_full.png", 1920, 1080)
    background.x = _CX
    background.y = _CY
    background.xScale = 2
    background.yScale = 2

    local qtdArrow = display.newImageRect(sceneGroup, "image/spriteSheet/arrow_reta.png", 54, 54)
    qtdArrow.x = _L*0.925
    qtdArrow.y = 150
    qtdArrow.xScale = 2
    qtdArrow.yScale = 2

    textArrow = display.newText( " x"..tostring(user.arrowQtd), qtdArrow.x+100, qtdArrow.y, native.newFont( "Augusta"), 90 )
    textArrow:setFillColor( 255, 255, 255 )

    textScore = display.newText( "SCORE  "..tostring(user.xp), _CX-300, _CY * 0.15, native.newFont( "Augusta"), 110 )
    textScore:setFillColor( 255, 255, 255 )

    for i=1,1 do 
        lane[i] = display.newImageRect(sceneGroup, "image/cenarios/road.png", 3500, 100)
        lane[i].x = _CX * 0.775
        if(i==1) then
            lane[i].y = _B * 0.884
    -- else
        -- lane[i].y = _B - 150
        end
        lane[i].id = i
    end 

    local rect1 = display.newRect( _R * 0.7, _B+75 ,1500,20)
    rect1:setFillColor(0,0,0,0)
    rect1.strokeWidth = 6
    rect1:setStrokeColor(0)
    physics.addBody(rect1,'static',{bounce=0.0,friction=0.0})

    -- castelo = display.newImageRect(sceneGroup, "image/cenarios/castelo.png", 800, 700)
    -- castelo.id = "castelo"
    -- castelo.name = "castelo"
    -- castelo.x = _R * 0.9
    -- castelo.y = _B * 0.63
    -- castelo.xScale = 2
    -- castelo.yScale = 2
    -- sceneGroup:insert(castelo)
    -- physics.addBody(castelo,'dynamic',{isSensor= false,radius=770,density=500.0,bounce=0.0,friction=0.3})

    -- castelo2 = display.newImageRect(sceneGroup, "image/cenarios/castelo_inAttack.png", 800, 700)
    -- castelo2.x = _R * 0.9
    -- castelo2.y = _B * 0.63
    -- castelo2.xScale = 2
    -- castelo2.yScale = 2
    -- sceneGroup:insert(castelo2)
    -- physics.addBody(castelo2,'dynamic',{isSensor= false,radius=770,density=500.0,bounce=0.0,friction=0.3})

    -- castelo3 = display.newImageRect(sceneGroup, "image/cenarios/castelo_destroy.png", 800, 555)
    -- castelo3.x = _R * 0.9
    -- castelo3.y = _B * 0.735
    -- castelo3.xScale = 1.9
    -- castelo3.yScale = 1.8
    -- sceneGroup:insert(castelo3)
    -- --physics.addBody(castelo3,'dynamic',{isSensor= false,radius=770,density=500.0,bounce=0.0,friction=0.3})

    -- castelo.isVisible = true
    -- castelo2.isVisible = false
    -- castelo3.isVisible = false

    castelo = display.newSprite(castleSheet, castleSequenceData)
    --display.newImageRect(sceneGroup, "image/cenarios/castelo.png", 800, 700)
    castelo.id = "castelo"
    castelo.name = "castelo"
    castelo.width = 800
    castelo.height = 700
    castelo.x = _R * 0.9
    castelo.y = _B * 0.63
    castelo.xScale = 1.15
    castelo.yScale = 1.2
    sceneGroup:insert(castelo)
    physics.addBody(castelo,'dynamic',{isSensor= false,radius=770,density=500.0,bounce=0.0,friction=0.3})
    castelo:setSequence("complete")
    castelo:play()
    castelo.isVisible = true;

    player = display.newSprite(playerSheet, playerSequenceData)     
    player.x = _CX / 0.37
    player.y = _CY / 0.82
    player.force = 0
    player.id = "player_shoot"
    player.xScale = 2.5
    player.yScale = 2.5
    sceneGroup:insert(player)
    --physics.addBody(player,'static',{bounce=0.0})
    player:setSequence("stop")
    player:play()
    player.isVisible = true;


    local function stop()
        player:setSequence("stop")
        player:play() 
    end

    local function countArrowText()
        textArrow.text = " x"..tostring(user.arrowQtd)
    end

    local function countScoreText()
        textScore.text = "SCORE  "..tostring(user.xp)
    end
 
    function castleHealthDemage()
        local maxHealth = 900
        local currentHealth = 900

        healthBar = display.newRoundedRect(_R * 0.6 + 180, 150, user.castleLife, 60,60)
        healthBar:setFillColor( 0, 0, 0 )

        damageBar = display.newRoundedRect(_R * 0.6 + 180 , 150, 0, 60,30)
        damageBar:setFillColor( 255, 0, 0 )

        nameBar = display.newRoundedRect(_R * 0.83, 89, 500, 60,7)
        nameBar:setFillColor (.50, .50, .50)
        nameBar.strokeWidth = 5
        nameBar:setStrokeColor(0,0,0)

        myText = display.newText( "Castle", nameBar.x-50, nameBar.y, native.newFont( "Augusta"), 70 )
        myText:setFillColor( 255, 255, 255 )

        lifeBar = display.newRoundedRect(_R * 0.8, 211, 550, 60,7)
        lifeBar:setFillColor (.50, .50, .50)
        lifeBar.strokeWidth = 5
        lifeBar:setStrokeColor(0,0,0)

        life = display.newText( tostring(currentHealth).." / "..tostring(maxHealth), lifeBar.x-25, lifeBar.y, native.newFont( "Augusta"), 70 )
        myText:setFillColor( 255, 255, 255 )

        circle = display.newCircle( _R*0.925, 150, 125 )

        local paint = {
            type = "image",
            filename = "image/cenarios/castle_life.png"
        }

        circle.fill = paint

        local function updateDamageBar()
            damageBar.width = maxHealth - currentHealth
            damageBar.x = healthBar.x - (healthBar.width/2 - damageBar.width/2)
            if(currentHealth < 0) then
                currentHealth = 0
            end
            life.text = tostring(currentHealth).." / "..tostring(maxHealth)
        end
    
        local closure = function(damageTaken)
            currentHealth = currentHealth - damageTaken
            if(currentHealth  <= 600 and currentHealth > 0) then
                -- castelo.isVisible = false
                -- castelo2.isVisible = true
                -- display.remove(castelo)
                -- castelo2.id = "castelo"
                -- castelo2.name = "castelo"
                castelo:setSequence("on_attack")
                castelo:play()
            elseif(currentHealth <= 0) then
                timer.performWithDelay( 1000, onGameOver )
            end
            updateDamageBar()
        end
        return closure
    end

    castleLife = castleHealthDemage()


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
            --enemySendSpeed = enemySendSpeed - enemyIncrementSpeed
            if(enemySendSpeed <= enemyMaxSendSpeed) then 
                enemySendSpeed = enemyMaxSendSpeed
            end

            --temp = math.random(1,3)
            temp = 1
            --if(temp == 1) then 
                enemy[enemyCounter] = display.newSprite(orcSheet1, orcSequenceData)
            --elseif(temp == 2) then 
               --- enemy[enemyCounter] = display.newSprite(pirateSheet2, pirateSequenceData)
            --else 
               -- enemy[enemyCounter] = display.newSprite(pirateSheet3, pirateSequenceData)
            --end

            enemy[enemyCounter].x = _L - 50
            enemy[enemyCounter].y = lane[1].y-75
            enemy[enemyCounter].id = "enemy"
            enemy[enemyCounter].name = "enemy"..temp
            enemy[enemyCounter].xScale = 3
            enemy[enemyCounter].yScale = 3
            enemy[enemyCounter].gravityScale = -30
            physics.addBody(enemy[enemyCounter],'kinematic',{isSensor=true,radius = 80,bounce=0.0,friction=0.0})
            enemy[enemyCounter].isFixedRotation = true 
            sceneGroup:insert(enemy[enemyCounter])

            transition.to(enemy[enemyCounter], {x=_R+50, time=enemyTravelSpeed, onComplete=function(self) 
                 if(self~=nil) then 
                    display.remove(self);
                end 
            end})

            enemy[enemyCounter]:setSequence("run")
            enemy[enemyCounter]:play()
        end
    end

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

    local function enemyHit(x,y)
        audio.play(_ENEMYHIT)

        poof = display.newSprite(poofSheet, poofSequenceData)
            poof.x = x
            poof.y = y
            sceneGroup:insert(poof)
        poof:setSequence("puff")
        poof:play()

        local function removePoof()
            if(poof~=nil) then 
                display.remove(poof)
            end
        end
        timer.performWithDelay(255, removePoof, 1)
    end

    local function castleHit(x,y)
        audio.play(_ENEMYHIT)

        poof_collision = display.newSprite(collisionSheet, collisionSequenceData)
        poof_collision.x = x
        poof_collision.y = y
        sceneGroup:insert(poof_collision)
        poof_collision:setSequence("puff_collision")
        poof_collision:play()

        local function removePoofCollision()
            if(poof_collision~=nil) then 
                display.remove(poof_collision)
            end
        end
        timer.performWithDelay(255, removePoofCollision, 1)
    end

    local function onCollision(event)

        local function removeOnEnemyHit(obj1, obj2)
            display.remove(obj1)
            display.remove(obj2)
            user.arrowQtd =  user.arrowQtd + user.arrowRecovered
            if(user.arrowQtd > 30) then
                user.arrowQtd = 30
            end
            loadsave.saveTable(user, "user.json")
            countArrowText()
            if(obj1.id == "enemy") then 
                enemyHit(event.object1.x, event.object1.y)
                if(obj1.name == "enemy1") then
                    user.xp = user.xp + user.orc1Xp
                    loadsave.saveTable(user, "user.json")
                    countScoreText()
                elseif(obj1.name == "enemy2") then

                else

                end
            else
                enemyHit(event.object2.x, event.object2.y)
                if(obj2.name == "enemy1") then
                    user.xp = user.xp + user.orc1Xp
                    loadsave.saveTable(user, "user.json")
                    countScoreText()
                elseif(obj2.name == "enemy2") then

                else

                end
            end
        end

        local function removeOnPlayerHit(obj1, obj2)
            if(obj1 ~= nil and obj1.id == "enemy") then
                print(1)
                castleHit(event.object1.x+80, event.object1.y)
                enemyHit(event.object1.x, event.object1.y)
                castleLife(200)
                display.remove(obj1)
            end
            if(obj2 ~= nil and obj2.id == "enemy") then
                print(2)
                castleHit(event.object2.x+80, event.object2.y)
                enemyHit(event.object2.x, event.object2.y)
                castleLife(900)
                display.remove(obj2)
            end
        end

        local function spriteListenerEnemy( event )
            if (event.phase == "loop" and event.target.sequence == "attack" ) then
                removeOnPlayerHit(nil, evento)
            end
        end

        if((event.object1.id == "bullet" and event.object2.id == "enemy") or (event.object1.id == "enemy" and event.object2.id == "bullet")) then 
            removeOnEnemyHit(event.object1, event.object2)
        elseif(event.object1.id == "enemy" and event.object2.id == "castelo") then 
            evento = event.object1
            enemy[enemyCounter]:addEventListener( "sprite", spriteListenerEnemy )
            transition.cancel()
            enemy[enemyCounter]:setSequence("attack")
            enemy[enemyCounter]:play()
        elseif(event.object1.id == "castelo" and event.object2.id == "enemy") then 
            evento = event.object2
            enemy[enemyCounter]:addEventListener( "sprite", spriteListenerEnemy )
            transition.cancel()
            enemy[enemyCounter]:setSequence("attack")
            enemy[enemyCounter]:play()
        end

    end


    local function shoot(event)
        audio.play(_THROW)

        bulletCounter = bulletCounter + 1
        bullets[bulletCounter] = display.newImageRect(sceneGroup, "image/spriteSheet/Arrow.png", 54, 54)
        bullets[bulletCounter].x = player.x  
        bullets[bulletCounter].y = player.y
        bullets[bulletCounter].id = "bullet"
        sceneGroup:insert(bullets[bulletCounter])
        physics.addBody(bullets[bulletCounter],'dynamic',{density = 20.0, bounce = 0.2, radius=4})
        bullets[bulletCounter].isSensor = true
        local vx, vy = (event.x-event.xStart)*-1, (event.y-event.yStart)*-1
        bullets[bulletCounter].rotation = (math.atan2(vy*-1, vx *-1) * 180 / math.pi)
        bullets[bulletCounter]:setLinearVelocity( vx * forceMultiplier ,vy * forceMultiplier )
        bullets[bulletCounter].angularVelocity = -40
        bullets[bulletCounter].gravityScale = 2


        if(self~=nil) then 
            display.remove(self)
            user.arrowQtd =  user.arrowQtd - 1
            loadsave.saveTable(user, "user.json")
            countArrowText()
        end
    end

    
    local function enterFrame( )
        forceMultiplier = forceMultiplier * perFrameDelta
        if(forceMultiplier >=1 and forceMultiplier <=2) then
            line:setStrokeColor(0,255,0)
        elseif(forceMultiplier > 2 and forceMultiplier <= 3) then
            line:setStrokeColor(255,255,0)
        elseif(forceMultiplier > 3) then
            line:setStrokeColor(255,0,0)
        end
        print(forceMultiplier)
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
                    line.strokeWidth = 8
                    line.alpha = 0.6  --MOD 
                elseif(event.phase == "moved") then
                    display.remove( line )
                    line = display.newLine( event.xStart, event.yStart, eventX, eventY )
                    line.strokeWidth = 8  
                    line.alpha = 0.6 --MOD
                    line:setStrokeColor(0,255,0)
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

    function onGameOver()
        audio.play(_GAMEOVER)

        -- if(tmr_playershoot) then 
        --     timer.cancel(tmr_playershoot)
        -- end 
        player:removeEventListener( "sprite", spriteListener )
        Runtime:removeEventListener( "touch", playerShoot)
        Runtime:removeEventListener("enterFrame", sendEnemies)
        Runtime:removeEventListener("collision", onCollision)
        Runtime:removeEventListener( "enterFrame", verificaTotalDeFlechas)

        transition.pause()

        display.remove(player)
        --display.remove(castelo2)
        display.remove(healthBar)
        display.remove(damageBar)
        display.remove(nameBar)
        display.remove(myText)
        display.remove(life)
        display.remove(lifeBar)
        display.remove(circle)
        display.remove(qtdArrow)
        display.remove(textArrow)

        -- for i=1,#lane do
        --     lane[i]:removeEventListener("touch", onLaneTouch)
        -- end

        for i=1,#enemy do
            if(enemy[i] ~= nil) then 
                display.remove(enemy[i]) 
            end
        end 

        castelo3 = display.newImageRect(sceneGroup, "image/cenarios/castelo_destroy.png", 800, 555)
        castelo3.x = _R * 0.9
        castelo3.y = _B * 0.728
        castelo3.xScale = 2
        castelo3.yScale = 1.8
        sceneGroup:insert(castelo3)
        castelo3.isVisible = true

        gameoverBackground = display.newRect(sceneGroup, 0, 0, 1920, 1080)
        display.remove(castelo)
        -- castelo.width = 800
        -- castelo.height = 700
        -- castelo.x = _R * 0.9
        -- castelo.y = _B - 50
        -- castelo.xScale = 0.9
        -- castelo.yScale = 0.9
        -- castelo:setSequence("destroy")
        -- castelo:play()


        gameoverBackground.x = _CX
        gameoverBackground.y = _CY
        gameoverBackground.xScale = 2
        gameoverBackground.yScale = 2
        gameoverBackground:setFillColor(0)
        gameoverBackground.alpha = 0.6

        gameOverBox = display.newImageRect(sceneGroup, "image/cenarios/game_over.png",1200, 300)
            gameOverBox.x = _CX 
            gameOverBox.y = _CY*0.6
  

        if(user.continue > 0 ) then    
            btn_Continue = widget.newButton {
                width = 520,
                height = 200,
                label = "CONTINUE x "..user.continue,
                labelColor = { default={ 255, 255, 255 } },
                font = native.newFont( "Augusta"),
                fontSize = 64,
                defaultFile = "image/cenarios/buttonDefault.png",
                overFile = "image/cenarios/buttonOver.png",
                onEvent = restartGame
            }
            btn_Continue.x = _CX
            btn_Continue.y =  _CY / 0.8
            sceneGroup:insert(btn_Continue)
        end

        btn_returnToMenu = widget.newButton {
            width = 520,
            height = 200,
            label = "MENU",
            labelColor = { default={ 255, 255, 255 } },
            font = native.newFont( "Augusta"),
            fontSize = 64,
            defaultFile = "image/cenarios/buttonDefault.png",
            overFile = "image/cenarios/buttonOver.png",
            onEvent = returnToMenu
        }
        btn_returnToMenu.x = _CX
        btn_returnToMenu.y =  _CY / 0.65
        sceneGroup:insert(btn_returnToMenu)
    end

    -- Add sprite listener
    player:addEventListener( "sprite", spriteListener )
    Runtime:addEventListener( "touch", playerShoot)
    Runtime:addEventListener( "enterFrame", sendEnemies)
    Runtime:addEventListener( "collision", onCollision )
    Runtime:addEventListener( "enterFrame", verificaTotalDeFlechas)   
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