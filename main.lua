-- FILE: main.lua
-- DESCRIPTION: start the app, declare some variables, and setup the player save file

-- APP OPTIONS
_APPNAME = "Save The Castle"
_FONT = "Augusta"
_SHOOTUPGRADECOST = 35
_LIVESUPGRADECOST = 100
_SHOWADS = true 

-- CONSTANT VALUES
_CX = display.contentWidth*0.5
_CY = display.contentHeight*0.5
_CW = display.contentWidth
_CH = display.contentHeight
_T = display.screenOriginY -- Top
_L = display.screenOriginX -- Left
_R = display.viewableContentWidth - _L -- Right
_B = display.viewableContentHeight - _T-- Bottom

-- hide the status bar
display.setStatusBar( display.HiddenStatusBar )

-- include composer
local composer = require "composer"

-- include load/save library from coronarob
loadsave = require("loadsave")

-- load up some audio
_BACKGROUNDMUSIC = audio.loadStream("audio/background-music.mp3")
_THROW = audio.loadSound("audio/throw.wav")
_ENEMYHIT = audio.loadSound("audio/enemy-hit.wav")
_PLAYERHIT = audio.loadSound("audio/player-hit.mp3")
_GAMEOVER = audio.loadSound("audio/game-over.wav")
_CLICK = audio.loadSound("audio/click.mp3")

-- set up a saved file for our user
user = loadsave.loadTable("user.json")
user = {}
user.continue = 3
user.arrowRecovered = 5
user.arrowQtd = 10
user.arrowQtdLevel = 1
user.arrowQtdLevelMax = 3
user.arrowDamage = 100
user.arrowDamageLevel = 1
user.arrowDamageLevelMax = 3
user.castleLife = 900
user.castleLifeLevel = 1
user.castleLifeLevelMax = 3
user.orc1Damage = 90
user.orc2Damage = 105
user.orc3Damage = 120
user.orcGiantDamage = 180
user.orc1Life = 100
user.orc2Life = 120
user.orc3Life = 150
user.orcGiantLife = 300
user.xp = 0
user.orc1Xp = 25
user.orc2Xp = 50
user.orc3Xp = 100
user.orcGiantXp = 250
user.playsound = true
user.exitMenu = false
loadsave.saveTable(user, "user.json")

composer.gotoScene("scene_menu")