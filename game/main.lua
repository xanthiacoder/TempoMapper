--[[
screen resolution = 1280 x 720 px
screen chars = 160 x 45 (font)
screen chars = 160 x 90 (font2x)

ansicanvas dimensions:
should be variable to allow making UI assets
- set max as 160x90 ? (max resolution 1280x720)
4x4 ?
8x8 ?
16x16
24x24
32x32
48x48
64x64
]]

--[[
Steam Deck : Game Mode
input mode : WASD + Mouse

L1 - scroll wheel down
R1 - scroll wheel up
L2 - Right mouse click
R2 - Left mouse click

Select - Tab
Start - Esc

Left Trackpad
up - 1
down - 3
left - 4
right - 2

Right Trackpad
mouse movement
click - left mouse click

D-Pad
up - up
down - down
left - left
right - right

Left joystick
up - w
down - s
left - a
right - d
click - shift

right joystick
joystick mouse
click - left mouse click

Face buttons
A - space
B - e
X - r
Y - f

---

Steam deck desktop mode (default)

select - tab
start - escape

A - return
B - escape
X - (raise virtual keyboard)
Y - space

left trackpad
mouse scroll (hard to control)

right trackpad
mouse movement

left joystick
up - up
down - down
left - left
right - right

d-pad
up - up
down - down
left - left
right - right

L1 - lctrl
L2 - right mouse click

R1 - lalt (arrows - select char)
L2 - left mouse click

L4 - lshift (quicksave)
L5 - lgui

R4 - pageup (WASD canvas size)
R5 - pagedown

]]

--[[ Major Scales

A  = a  b  c+ d  e  f+ g+
B- = b- c  d  e- f  g  a
B  = b  c+ d+ e  f+ g+ a+
C  = c  d  e  f  g  a  b
D- = d- e- f  g- a- b- c
D  = d  e  f+ g  a  b  c+
E- = e- f  g  a- b- c  d
E  = e  f+ g+ a  b  c+ d+
F  = f  g  a  b- c  d  e
F+ = f+ g+ a+ b  c+ d+ e+ <-- special condition e+ (f)
G- = g- a- b- c- d- e- f  <-- special condition c- (b)
G  = g  a  b  c  d  e  f+
A- = a- b- c  d- e- f  g

]]

love.filesystem.setIdentity("TempoMapper") -- for R36S file system compatibility
love.mouse.setVisible( false ) -- make mouse cursor invis, use bitmap cursor
love.graphics.setDefaultFilter("nearest", "nearest") -- for nearest neighbour, pixelart style

local json = require("lib.json")
local ansi = require("lib.ansi")

-- TEXT_BLOCKS = "▄ █ ▀ ▌ ▐ ░ ▒ ▓" -- cp437
-- TEXT_SYMBOLS = "○ ■ ▲ ▼ ► ◄" -- cp437
-- TEXT_BOX = "╦ ╗ ╔ ═ ╩ ╝ ╚ ║ ╬ ╣ ╠ ╥ ╖ ╓ ╤ ╕ ╒ ┬ ┐ ┌ ─ ┴ ┘ └ │ ┼ ┤ ├ ╨ ╜ ╙ ╧ ╛ ╘ ╫ ╢ ╟ ╪ ╡ ╞" -- cp437

-- user monoFont to display, 11 columns x 17 rows = 187 chars
local charTable = {
  [1]  = {"█","▓","▒","░","▄","▀","▌","▐","/","|","\\"},
  [2]  = {"≈","■","¥","ε","δ","Φ","Ω","∩","♪","∞","≡"},
  [3]  = {"╔","═","╦","╩","╗","║","╠","╬","╣","╚","╝"},
  [4]  = {"┌","─","┬","┴","┐","│","├","┼","┤","└","┘"},
  [5]  = {"╓","╒","╤","╥","╨","╧","╥","╤","╖","╕","."},
  [6]  = {"╫","╪","╟","╞","╢","╡","╙","╘","╜","╛",","},
  [7]  = {"!","@","#","$","%","^","&","*","(",")"," "},
  [8]  = {"a","b","c","d","e","f","g","h","i","j","k"},
  [9]  = {"l","m","n","o","p","q","r","s","t","u","v"},
  [10] = {"w","x","y","z","-","=","_","+","[","]","'"},
  [11] = {"A","B","C","D","E","F","G","H","I","J","K"},
  [12] = {"L","M","N","O","P","Q","R","S","T","U","V"},
  [13] = {"W","X","Y","Z","<",">",",",".",";",":","?"},
  [14] = {"1","2","3","4","5","6","7","8","9","0","`"},
  [15] = {"☺","☻","♥","♦","♣","♠","•","◘","○","◙","♀",},
  [16] = {string.char(14),string.char(15),string.char(16),string.char(17),string.char(18),string.char(19),string.char(20),string.char(21),string.char(22),string.char(23),string.char(24),},
  [17] = {string.char(25),string.char(26),string.char(27),string.char(28),string.char(29),string.char(30),string.char(31),string.char(32),string.char(33),string.char(34),string.char(35),},
}


-- first item is the menu category, the rest are the category's options
local menuTable = {
  [1] = {"File"    , "Load" , "Save" , "Quit" },
  [2] = {"Game"    , "Edit" , "Play" },
  [3] = {"Scene"   , "Edit" , "Play" , "Jump" },
  [4] = {"Options" , "Sound", "Zoom" , "Help" },
}

local selected = {
  color = color.white,
  char  = "█",
  bmp   = "",
  bmpnumber = 1,
  viewport = 1,
  textmode = 2, -- 1 = 8x16, 2 = 8x8
  menuRow = 0, -- nothing selected
  menuOption = 0, -- nothing selected (menuItemselects item on menuTable)
}

-- cursor text to display when hovering over a fixed 8x8 coordinate
-- fullscreen 160 x 90
-- initialize table
local hover = {}
for i = 1,160 do -- number of columns (x)
  hover[i] = {}
  for j = 1,90 do -- number of rows (y)
    hover[i][j] = ""
  end
end
-- enter game data

local click = {}
for i = 1,160 do -- number of columns (x)
  click[i] = {}
  for j = 1,90 do -- number of rows (y)
    click[i][j] = ""
  end
end

-- init game data
local game = {}

-- init game help
game.inputTips = "" -- to display contextual help for inputs

-- set game timers
game.timeThisSession = 0
game.autosaveCooldown = 0

-- set game flags (editor)
game.insertMode = false

-- set game message
game.message = ""
game.messageViewport = 1

-- set game mode
-- "edit" - game editor mode ; "play" - game playing mode
game.mode = "edit"

-- set game scene
game.scene = "TempoMapper" -- anything but "title" to prevent showing the title screens

-- set game script
game.script = ""

-- detect viewport
game.width, game.height = love.graphics.getDimensions( )
print("viewport: "..game.width.."x"..game.height)

-- set default cursor coord
game.cursorx = 1
game.cursory = 1

-- set default player coord (shown as "P" while standing, "p" while squatting)
-- 0,0 is off-screen; coord follows monoFont2x 8x8px 80x60 chars, screen 1 only)
-- for movement, x increments by 1, y increments by 2
-- movement using arrow keys while in "play" mode
game.playerx = 41
game.playery = 31 -- MUST be odd number

-- set default player display char
-- "P" - standing player
-- "p" - crouching player
game.playerChar = "P"

-- set default canvas size (16x16)
game.canvasx = 80
game.canvasy = 60

-- set default char table selected [1..11][1..14]
game.charx = 1
game.chary = 1

-- set default color number selected
game.colorSelected = 15
game.bgcolorSelected = 0 -- 16 is transparent, 0-15 is solid color

-- set showCloseup
game.showCloseup = false

-- detect system OS
game.os = love.system.getOS() -- "OS X", "Windows", "Linux", "Android" or "iOS"
if love.filesystem.getUserDirectory( ) == "/home/ark/" then
	game.os = "R36S"
end
print("systemOS: "..game.os)

-- check / create file directories
if love.filesystem.getInfo("autosave") == nil then
  if game.os == "R36S" then
    os.execute("mkdir " .. love.filesystem.getSaveDirectory()) -- OS creation
    os.execute("mkdir " .. love.filesystem.getSaveDirectory() .. "//autosave")
    print("R36S: created directory - autosave")
  else
    love.filesystem.createDirectory("autosave")
    print("Created directory - autosave")
  end
end
if love.filesystem.getInfo("quicksave") == nil then
  if game.os == "R36S" then
    os.execute("mkdir " .. love.filesystem.getSaveDirectory() .. "//quicksave")
    print("R36S: created directory - quicksave")
  else
    love.filesystem.createDirectory("quicksave")
    print("Created directory - quicksave")
  end
end
if love.filesystem.getInfo("ansiart") == nil then
  if game.os == "R36S" then
    os.execute("mkdir " .. love.filesystem.getSaveDirectory() .. "//ansiart")
    print("R36S: created directory - ansiart")
  else
    love.filesystem.createDirectory("ansiart")
    print("Created directory - ansiart")
  end
end
if love.filesystem.getInfo("timelapse") == nil then
  if game.os == "R36S" then
    os.execute("mkdir " .. love.filesystem.getSaveDirectory() .. "//timelapse")
    print("R36S: created directory - timelapse")
  else
    love.filesystem.createDirectory("timelapse")
    print("Created directory - timelapse")
  end
end
if love.filesystem.getInfo("audio") == nil then
  if game.os == "R36S" then
    os.execute("mkdir " .. love.filesystem.getSaveDirectory() .. "//audio")
    print("R36S: created directory - audio")
  else
    love.filesystem.createDirectory("audio")
    print("Created directory - audio")
  end
end
local success = love.filesystem.remove( "audio/.DS_Store" ) -- cleanup for MacOS
if success then
  print("DS_Store removed from audio directory")
else
  print("No files removed from audio directory")
end
local audioFiles = love.filesystem.getDirectoryItems( "audio" ) -- table of files in the audio directory

if love.filesystem.getInfo("data") == nil then
  if game.os == "R36S" then
    os.execute("mkdir " .. love.filesystem.getSaveDirectory() .. "//data")
    print("R36S: created directory - data")
  else
    love.filesystem.createDirectory("data")
    print("Created directory - data")
  end
end
local success = love.filesystem.remove( "data/.DS_Store" ) -- cleanup for MacOS
if success then
  print("DS_Store removed from data directory")
else
  print("No files removed from data directory")
end
local dataFiles = love.filesystem.getDirectoryItems( "data" ) -- table of files in the data directory

---@param filename string
---@param directory string
---@param data table
function saveData( filename , directory , data )

  -- save regularly
  if game.os ~= "R36S" then
    -- save data
    local success, message =love.filesystem.write(directory.."/"..filename, json.encode(data))
    if success then
	    print ('file created: '..directory.."/"..filename)
    else
      game.message = 'file not created: '..message
	    print ('file not created: '..message)
    end
  else
    -- save ansiart for R36S
    local f = io.open(love.filesystem.getSaveDirectory().."//"..directory.."/"..filename, "w")
    f:write(json.encode(data))
    f:close()
  end
end


-- init music data table
music = {}

function initMusic()

  music.position = 0
  music.duration = 0
  music.bars = {}
  music.tempoCurrent = 0
  music.tempoAverage = 0
  music.passage = {}
  music.beatCurrent = 0
  music.beatsPerBar = 4
  music.barTimeElapsed = 0
  music.barFirst = 0 -- first beat of FIRST BAR of the song
  music.barLast = 0 -- first beat of LAST BAR of the song
  music.waveform = nil
  music.waveData = nil
  music.audioData = nil
  music.sampleRate = nil
  music.channels = nil
  music.filename = ""
end

initMusic()




-- creates audio waveform image
function generateWaveform(imageWidth,imageHeight)
    local samples = music.audioData:getSampleCount()
    local samplesPerPixel = samples / imageWidth
    local maxAmplitude = 1

    for x = 0, imageWidth - 1 do
        local sampleIndex = math.floor(x * samplesPerPixel)
        local sum = 0

        for ch = 1, music.channels do
            if ch <= music.audioData:getChannelCount() then
                sum = sum + math.abs(music.audioData:getSample(sampleIndex, ch))
            end
        end

        local amplitude = sum / music.channels
        local y = math.floor((1 - amplitude / maxAmplitude) * imageHeight / 2)

        for i = y, imageHeight - y do
            music.waveData:setPixel(x, i, 1, 1, 1, 1)
        end
    end

    music.waveform:replacePixels(music.waveData)
end


function loadSong(fileName)
  -- Load the audio file for waveform display
  -- local fileAudio = 'audio/'.. fileName
  local fileData = 'data/'.. fileName
  if love.filesystem.getInfo(fileData) == nil then -- data doesn't exist
    print(fileData .. " does not exist, creating")
    -- saveData(fileName, "data", music) -- need to patch up filename
  else
    print(fileName .. " exist... will be loaded")
    -- music = json.decode(love.filesystem.read(fileData)) -- need to patch up filename
  end
  music.audioData = love.sound.newSoundData(fileName)
  music.sampleRate = music.audioData:getSampleRate()
  music.channels = music.audioData:getChannelCount()
	music.duration = music.audioData:getDuration()
	-- load the audio file for playback
	game.music = love.audio.newSource(fileName, "stream")
    -- Create an image to draw the waveform
    imageWidth, imageHeight = 640, 48
    music.waveData = love.image.newImageData(imageWidth, imageHeight)
    music.waveform = love.graphics.newImage(music.waveData)
    -- Generate the waveform
    generateWaveform(imageWidth,imageHeight)

end

-- hardcode music filename for testing
music.filename = "audio/SEVENTEEN - Sample 2.ogg"
loadSong(music.filename)



local colorpalette = {}

-- initialize max ansiArt 160x90 chars (8x8 font)
-- viewport 1 = 80 x 29 (8x16 font)
-- viewport 2 = 80 x 29 (8x16 font)
MAX_CANVAS_X = 160
MAX_CANVAS_Y = 90
local ansiArt = {}
-- i = Canvas row, Y
-- j = Canvas Column, X
for i = 1,MAX_CANVAS_Y do
  ansiArt[i] = {}
  for j = 1,MAX_CANVAS_X do
    ansiArt[i][j+(j-1)] = color.darkgrey
    ansiArt[i][j*2] = " "
  end
end

---@param x integer position in chars (0..159) font2x size
---@param y integer position in chars (0..89) font2x size
function drawPalette( x, y )
  love.graphics.setColor( color.white )
  love.graphics.print("╔════════════════╗", monoFont2x, 141*FONT2X_WIDTH, 4*FONT2X_HEIGHT)
  love.graphics.print("║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n", monoFont2x, 141*FONT2X_WIDTH, 5*FONT2X_HEIGHT)
  love.graphics.print("║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n║\n", monoFont2x, 158*FONT2X_WIDTH, 5*FONT2X_HEIGHT)
  love.graphics.print("╚════════════════╝", monoFont2x, 141*FONT2X_WIDTH, 21*FONT2X_HEIGHT)

  drawXTUI16(colorpalette,142,5)

end

---comment
---@param x integer column coordinate in exact pixel
---@param y integer row coordinate in exact pixel
function drawCharTable( x, y)

  -- draw background color
  if game.bgcolorSelected >= 0 and game.bgcolorSelected <= 15 then
    love.graphics.setColor(color[game.bgcolorSelected])
  else
    love.graphics.setColor(color.black)
  end

  love.graphics.setColor(selected.color)
  love.graphics.setFont(monoFont)
  for i = 1,17 do
    for j = 1,11 do
      love.graphics.setColor(selected.color)
      love.graphics.setFont(monoFont)
      love.graphics.print(charTable[i][j], x + (((j-1)*2)*FONT_WIDTH), y + ((i-1)*FONT_HEIGHT) )
    end
  end

  -- highlight current selection
  love.graphics.setColor( color.white )
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", x+(((game.charx-1)*2)*FONT_WIDTH), y+((game.chary-1)*FONT_HEIGHT), FONT_WIDTH, FONT_HEIGHT)

end


function loadData()
  local tempArt = json.decode(love.filesystem.read("wip/data.xtui")) -- manually set background
  local canvasx = 0
  local canvasy = 0
  -- check for first instance of \n in table (first \n)
  local loop = 2
  while canvasx == 0 do
  	if string.find(tempArt[loop], "\n") ~= nil then
  		canvasx = loop/2
  	end
  	loop = loop + 2
  end
  canvasy = #tempArt/(canvasx*2)

  -- load tempArt into ansiArt
  game.canvasx = canvasx
  game.canvasy = canvasy
  local artRow = 1
  local artColumn = 1
  print("Loaded ansiArt data: "..canvasx..","..canvasy)
  for i = 1,canvasx*canvasy do
    if artColumn <= canvasx then
      ansiArt[artRow][(artColumn*2)-1] = tempArt[(i*2)-1]
      ansiArt[artRow][artColumn*2] = tempArt[i*2]
      artColumn = artColumn + 1
    else
      artColumn = 1
      artRow = artRow + 1
      ansiArt[artRow][(artColumn*2)-1] = tempArt[(i*2)-1]
      ansiArt[artRow][artColumn*2] = tempArt[i*2]
      artColumn = artColumn + 1
    end
  end

end



function love.load()
  -- Your game load here

  -- piano
  piano = {
    [28] = love.audio.newSource("samples/piano28.ogg", "static"),
	  [29] = love.audio.newSource("samples/piano29.ogg", "static"),
	  [30] = love.audio.newSource("samples/piano30.ogg", "static"),
	  [31] = love.audio.newSource("samples/piano31.ogg", "static"),
	  [32] = love.audio.newSource("samples/piano32.ogg", "static"),
	  [33] = love.audio.newSource("samples/piano33.ogg", "static"),
	  [34] = love.audio.newSource("samples/piano34.ogg", "static"),
	  [35] = love.audio.newSource("samples/piano35.ogg", "static"),
	  [36] = love.audio.newSource("samples/piano36.ogg", "static"),
	  [37] = love.audio.newSource("samples/piano37.ogg", "static"),
	  [38] = love.audio.newSource("samples/piano38.ogg", "static"),
	  [39] = love.audio.newSource("samples/piano39.ogg", "static"),
	  [40] = love.audio.newSource("samples/piano40.ogg", "static"),
  }

  -- fonts
  monoFont = love.graphics.newFont("fonts/"..FONT, FONT_SIZE)
  monoFont2s = love.graphics.newFont("fonts/"..FONT, FONT_SIZE*2)
  monoFont4s = love.graphics.newFont("fonts/"..FONT, FONT_SIZE*4)
  monoFont2x = love.graphics.newFont("fonts/"..FONT2X, FONT2X_SIZE)
  monoFont2x4s = love.graphics.newFont("fonts/"..FONT2X, FONT2X_SIZE*4)
  pixelFont = love.graphics.newFont("fonts/"..FONT2X, 1)
  love.graphics.setFont( monoFont )
  -- print(monoFont:getWidth("█"))
  -- print(monoFont:getHeight())
  love.graphics.setFont( monoFont2x )
  -- print(monoFont2x:getWidth("█"))
  -- print(monoFont2x:getHeight())


  -- xtui screens using monoFont
  xtui = {}
  xtui["piano-13"] = json.decode(love.filesystem.read("ansiart/0-piano-13keys.xtui"))

  -- [scene number][screen 1,screen 2,screen 1 bgcolor, screen 2 bgcolor]
  screen = {}
  screen[1] = {
    [1] = json.decode(love.filesystem.read("xtui/4-xtuisplash1.xtui")),
    [2] = json.decode(love.filesystem.read("xtui/8-xtuisplash2.xtui")),
    [3] = 4,
    [4] = 8,
  }

  -- buttons
  button = {
    [1]  = json.decode(love.filesystem.read("xtui/button-01.xtui")),
    [2]  = json.decode(love.filesystem.read("xtui/button-02.xtui")),
    [3]  = json.decode(love.filesystem.read("xtui/button-03.xtui")),
    [4]  = json.decode(love.filesystem.read("xtui/button-04.xtui")),
    [5]  = json.decode(love.filesystem.read("xtui/button-05.xtui")),
    [6]  = json.decode(love.filesystem.read("xtui/button-06.xtui")),
    [7]  = json.decode(love.filesystem.read("xtui/button-07.xtui")),
    [8]  = json.decode(love.filesystem.read("xtui/button-08.xtui")),
    [9]  = json.decode(love.filesystem.read("xtui/button-09.xtui")),
    [10] = json.decode(love.filesystem.read("xtui/button-10.xtui")),
  }

  -- screen 2
  screen2 = {
    ["drawmode"] = json.decode(love.filesystem.read("xtui/0-drawmode.xtui")),
  }

  -- pointers
  pointer = love.graphics.newImage("img/pointer-wand.png")

  local tempData = love.filesystem.read("xtui/colorpalette_16.xtui")
  colorpalette = json.decode(tempData)

end

---@param xtui table containing color tables and text
---@param x integer in font2x chars (0..159)
---@param y integer in font2x chars (0..89)
function drawXTUI16(xtui, x, y)
  love.graphics.setColor(color.white)
  for i = 1,16 do
    love.graphics.print(xtui[i], monoFont2x, x*FONT2X_WIDTH, ((i-1)+y)*FONT2X_HEIGHT)
  end
end

---comment
---@param msg string Text message to display
---@param viewport integer 1..4 to switch location of display output
function drawMessage( msg, viewport)
  local rows = math.ceil(#msg/60)
  -- draw frame
  love.graphics.setColor(color.white)
  love.graphics.setFont(monoFont2x)
  for i = 1,62 do
    love.graphics.print("▄", (8+(i-1))*FONT_WIDTH, (FONT_HEIGHT/2)+((12)-(math.floor(rows/2)))*FONT_HEIGHT)
  end
  love.graphics.setFont(monoFont)
  for i = 1,rows+2 do
    love.graphics.print("▐", 7*FONT_WIDTH, ((12+i)-(math.floor(rows/2)))*FONT_HEIGHT )
  end
  love.graphics.setColor(color.darkgrey)
  for i = 1,62 do
      love.graphics.print("▀", (8+(i-1))*FONT_WIDTH, ((15+rows)-(math.floor(rows/2)))*FONT_HEIGHT)
  end
  love.graphics.setFont(monoFont)
  for i = 1,rows+2 do
    love.graphics.print("▌", (7+63)*FONT_WIDTH, ((12+i)-(math.floor(rows/2)))*FONT_HEIGHT )
  end

  love.graphics.setColor(color.grey)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("fill", 8*FONT_WIDTH, (13-(math.floor(rows/2)))*FONT_HEIGHT, 62*FONT_WIDTH, (rows+2)*FONT_HEIGHT )
  love.graphics.setColor(color.black)
  love.graphics.printf(msg, monoFont, 10*FONT_WIDTH, (14-(math.floor(rows/2)))*FONT_HEIGHT, 60*FONT_WIDTH, "left")
end


function drawButtons()
  love.graphics.setColor(color.white)
  love.graphics.setFont(monoFont2x)
  for i = 1,10 do
    love.graphics.print(button[i],0+((i-1)*128),480)
  end
end


---@param x integer coordinate using monoFont2x dimensions
---@param y integer coordinate using monoFont2x dimensions
function drawPlayer(x,y)

  -- make it blinking with alpha
  love.graphics.setFont(monoFont)
  if(math.floor(game.timeThisSession))%2 == 1 then
    love.graphics.setColor(1,1,1,1)
  else
    love.graphics.setColor(0.5,0.5,0.5,1)
  end
  love.graphics.print(game.playerChar,(game.playerx-1)*FONT2X_WIDTH, (game.playery-1)*FONT2X_HEIGHT)
end

function clearCanvas()
  for i = 1,game.canvasy do
    for j = 1,game.canvasx do
      ansiArt[i][j*2] = " "
    end
  end
end

---@param textmode integer 1..2 (1 = 8x16, 2 = 8x8)
---@param bgcolor integer 0..16 (0 black .. 16 transparent)
function drawArtCanvas(textmode, bgcolor)

  -- draw checkerboard
  local drawBright = true -- draw a bright box
  for i = 1,game.canvasy do -- iterate over rows
    if (i%2) == 0 then -- odd numbered row detected
      drawBright = true
    else
      drawBright = false
    end
    for j = 1,game.canvasx do -- iterate over columns
      if drawBright then
        -- draw bright box
        love.graphics.setColor(color.white)
        if textmode == 2 then
          love.graphics.rectangle("fill", 0+(j-1)*FONT2X_WIDTH, 0+(i-1)*FONT2X_HEIGHT, FONT2X_WIDTH, FONT2X_HEIGHT)
        else
          love.graphics.rectangle("fill", 0+(j-1)*FONT_WIDTH, 0+(i-1)*FONT_HEIGHT, FONT_WIDTH, FONT_HEIGHT)
        end
        drawBright = false
      else
        -- draw dark box
        love.graphics.setColor(color.darkgrey)
        if textmode == 2 then
          love.graphics.rectangle("fill", 0+(j-1)*FONT2X_WIDTH, 0+(i-1)*FONT2X_HEIGHT, FONT2X_WIDTH, FONT2X_HEIGHT)
        else
          love.graphics.rectangle("fill", 0+(j-1)*FONT_WIDTH, 0+(i-1)*FONT_HEIGHT, FONT_WIDTH, FONT_HEIGHT)
        end
        drawBright = true
      end
    end
  end

  -- draw background solid color
  if bgcolor == 16 then
    love.graphics.setColor(0,0,0,0) -- transparent
  else
    love.graphics.setColor(color[bgcolor])
  end
  love.graphics.setLineWidth(1)
  if textmode == 2 then
    love.graphics.rectangle( "fill", 0, 0, (game.canvasx)*FONT2X_WIDTH, (game.canvasy)*FONT2X_HEIGHT)
  else
    love.graphics.rectangle( "fill", 0, 0, (game.canvasx)*FONT_WIDTH, (game.canvasy)*FONT_HEIGHT)
  end

  -- draw ansiArt
  love.graphics.setColor(color.white)
  for i = 1,game.canvasy do
    for j = 1,game.canvasx do
      tempText = {
        ansiArt[i][j+(j-1)],
        ansiArt[i][j*2],
      }
      if textmode == 2 then
        love.graphics.print(tempText, monoFont2x, (j-1)*FONT2X_WIDTH, (i-1)*FONT2X_HEIGHT)
      else
        love.graphics.print(tempText, monoFont, (j-1)*FONT_WIDTH, (i-1)*FONT_HEIGHT)
      end
    end
  end

  -- draw canvas border
  love.graphics.setColor(color.brightcyan)
  love.graphics.setLineWidth(1)
  if textmode == 2 then
    love.graphics.rectangle("line", 0, 0, game.canvasx*FONT2X_WIDTH, game.canvasy*FONT2X_HEIGHT)
  else
    love.graphics.rectangle("line", 0, 0, game.canvasx*FONT_WIDTH, game.canvasy*FONT_HEIGHT)
  end

end


function drawMenu()
  local menuWidth = 2 -- menu category padding
  local optionsPadding = 0 -- menu options padding
  local blinking = {}
  -- make it blinking with alpha
  if(math.floor(game.timeThisSession))%2 == 1 then
    blinking = {1,0,0,1} -- red
  else
    blinking = {0.75,0.75,0.75,1} -- bright grey
  end
  love.graphics.setFont(monoFont)
  love.graphics.setColor(color.white)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("fill", 0, 0, 80*FONT_WIDTH, 1*FONT_HEIGHT) -- top menu background
  love.graphics.setColor(color.black)

  -- print menu categories
  for i = 1,#menuTable do
    if selected.menuRow == i then
      love.graphics.setColor(blinking)
      love.graphics.print("►",(menuWidth-1)*FONT_WIDTH,0)
      optionsPadding = menuWidth-2
    end
    love.graphics.setColor(color.black)
    love.graphics.print(menuTable[i][1],menuWidth*FONT_WIDTH, 0)
    menuWidth = menuWidth + #menuTable[i][1] + 2 -- padding
  end

  -- determine longest menu item length
  local maxCharLength = 0
  for i = 2,#menuTable[selected.menuRow] do
    if #menuTable[selected.menuRow][i] > maxCharLength then
      maxCharLength = #menuTable[selected.menuRow][i]
    end
  end

  -- draw menu options
  for i = 2,#menuTable[selected.menuRow] do
    love.graphics.setColor(color.white)
    love.graphics.rectangle("fill", optionsPadding*FONT_WIDTH, (i-1)*FONT_HEIGHT, (maxCharLength+4)*FONT_WIDTH, 1*FONT_HEIGHT)
    if selected.menuOption == i then
      love.graphics.setColor(blinking)
      love.graphics.print("►",(optionsPadding+1)*FONT_WIDTH,(i-1)*FONT_HEIGHT)
    end
    love.graphics.setColor(color.blue)
    love.graphics.print(menuTable[selected.menuRow][i], (optionsPadding+2)*FONT_WIDTH, (i-1)*FONT_HEIGHT)
  end

end


function love.draw()
  -- Your game draw here (from bottom to top layer)

    -- must be the start of love.draw, love.graphics.translate also resets at each love.draw
    if selected.viewport == 1 then
      love.graphics.translate( 0, 0 )
    end
    if selected.viewport == 2 then
      love.graphics.translate( -640, 0 )
    end
    if selected.viewport == 3 then
      love.graphics.translate( 0, -480 )
    end
    if selected.viewport == 4 then
      love.graphics.translate( -640, -480 )
    end

  -- draw game.inputTips
  love.graphics.setFont(monoFont)
  love.graphics.setColor(color.white)
  love.graphics.printf(game.inputTips, 640+(1*FONT_WIDTH), (29-28)*FONT_HEIGHT, 320, "left")


  -- render the ansiArt area
  drawArtCanvas(selected.textmode, game.bgcolorSelected)

  drawPalette(141, 4)

  -- responsively draw game.statusbar according to cursor position
  love.graphics.setColor( color.darkgrey )
  if game.cursory*8 <= math.floor(game.height/2) then
    -- cursor is in upper screen
    love.graphics.rectangle("fill", 0, game.height-FONT_HEIGHT, game.width, FONT_HEIGHT)
    love.graphics.setColor( color.black )
    love.graphics.setFont(monoFont)
    love.graphics.print("   "..game.statusbar, 0, game.height-FONT_HEIGHT)
      -- show selected color and char
    love.graphics.setColor(selected.color)
    love.graphics.printf(selected.char, monoFont, FONT_WIDTH, game.height-FONT_HEIGHT, 16, "left")

  else
    -- cursor is in lower screen
    love.graphics.rectangle("fill", 0, 0, game.width, FONT_HEIGHT)
    love.graphics.setColor( color.black )
    love.graphics.setFont(monoFont)
    love.graphics.print("   "..game.statusbar, 0, 0)
    -- show selected color and char
    love.graphics.setColor(selected.color)
    love.graphics.printf(selected.char, monoFont, FONT_WIDTH, 0, 16, "left")
  end

--  if love.keyboard.isDown("lshift") then
    -- draw screen 2 "drawmode"
--    love.graphics.setFont(monoFont)
--    love.graphics.setColor(color.white)
--    love.graphics.print(screen2["drawmode"],640, 0)
--  end

  -- draw cursor
  love.graphics.setColor( color.pulsingwhite )
  love.graphics.setLineWidth(1)
  if selected.textmode == 2 then
    love.graphics.rectangle( "line" , (game.cursorx-1)*8, (game.cursory-1)*8, FONT2X_WIDTH, FONT2X_HEIGHT)
  else
    love.graphics.rectangle( "line" , (game.cursorx-1)*8, (game.cursory-1)*8, FONT_WIDTH, FONT_HEIGHT)
  end

  -- draw viewports (debug only)
  love.graphics.setColor(color.brightcyan)
  love.graphics.setLineWidth(1)
--  love.graphics.rectangle("line",0,0,640,480)
--  love.graphics.printf("Viewport 1", monoFont, 0, 480/2, 640,"center")
--  love.graphics.rectangle("line",640,0,640,480)
--  love.graphics.printf("Viewport 2", monoFont, 640, 480/2, 640,"center")
  -- viewport 3 and 4 use different fonts
  if game.os == "R36S" then
    love.graphics.setFont(monoFont)
  else
    love.graphics.setFont(monoFont2x)
  end
--  love.graphics.rectangle("line",0,480,640,240)
  -- love.graphics.printf("Viewport 3", monoFont, 0, (240/2)+480, 640,"center")
  for i = 1,29 do
    if game.os == "R36S" then
      love.graphics.printf("Test 3",monoFont,0, 480+((i-1)*FONT_HEIGHT),640,"left")
    else
      -- render for computers
    end
  end
--  love.graphics.rectangle("line",640,480,640,240)
  -- love.graphics.printf("Viewport 4", monoFont, 640, (240/2)+480, 640,"center")
  for i = 1,29 do
    if game.os == "R36S" then
      love.graphics.printf("Test 4",monoFont,640, 480+((i-1)*FONT_HEIGHT),640,"left")
    else
      -- render for computers
    end
  end

  -- draw buttons
  drawButtons()

  -- draw hover and click items during "play" mode
  -- draw hover shadow first
  if game.mode == "play" then
    love.graphics.setFont(monoFont)
    love.graphics.setColor(color.black)
    love.graphics.print(hover[game.mousex][game.mousey],(game.mousex*FONT2X_WIDTH)+2,((game.mousey+2)*FONT2X_HEIGHT)+2)
    -- draw hover text
    love.graphics.setColor(color.white)
    love.graphics.print(hover[game.mousex][game.mousey],game.mousex*FONT2X_WIDTH,(game.mousey+2)*FONT2X_HEIGHT)

  end

  -- draw click - text message
  if game.message ~= "" then
    drawMessage( game.message, game.messageViewport )
  end

  -- draw pointer
  love.graphics.setColor(color.white)
  love.graphics.draw(pointer, love.mouse.getX(), love.mouse.getY())

  if game.scene == "title" then
    -- draw full screens last
    love.graphics.setFont(monoFont)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(color[screen[1][3]])
    love.graphics.rectangle("fill",0,0,640,480) -- screen 1 background
    love.graphics.setColor(color[screen[1][4]])
    love.graphics.rectangle("fill",640,0,640,480) -- screen 2 background
    love.graphics.setColor(color.white)
    love.graphics.print(screen[1][1],0,0) -- screen 1 foreground
    love.graphics.print(screen[1][2],640,0) -- screen 2 foreground
  end

  -- draw Player after everything else (not used now for editing)
  -- drawPlayer()

	-- draw audio waveform
  love.graphics.draw(music.waveform, 0, 0)


  -- draw music playhead position
  game.tooltip = "Filename: " .. music.filename .. "\nMusic position: " .. music.position
	music.position = game.music:tell("seconds")
	love.graphics.setColor( 1, 0, 0) -- set red color
	love.graphics.line(0 + imageWidth*(music.position/music.duration) , 0 , 0 + imageWidth*(music.position/music.duration), imageHeight)
	love.graphics.setColor( 1, 1, 1) -- reset to white

  -- visualising beats in a bar (needs tidying up)
  love.graphics.setFont(monoFont)
  love.graphics.setColor(color.brightcyan)
  love.graphics.print(game.tooltip, 0, 6*FONT2X_HEIGHT )
  love.graphics.print("Bars: " ..#music.bars, 0, 10*FONT2X_HEIGHT)
  if #music.bars > 1 then
    local durationBar  = music.bars[#music.bars] - music.bars[#music.bars-1]
    local durationBeat = durationBar / 4 -- assuming 4 beats per bar
    music.tempoCurrent = 60 / durationBeat -- 60 secs per min
    music.tempoAverage = 60 / ((music.bars[#music.bars] - music.bars[1]) / ((#music.bars - 1) * 4))
    love.graphics.print("Tempo: " .. music.tempoAverage, 0, 12*FONT2X_HEIGHT)
  end

  -- draw bars
  love.graphics.setColor(color.brightgreen)
  love.graphics.setLineWidth(1)
  for i = 1,#music.bars do
		love.graphics.line(0 + imageWidth*(music.bars[i]/music.duration) , 0 , 0 + imageWidth*(music.bars[i]/music.duration), FONT2X_HEIGHT)
  end
  love.graphics.setColor(color.brightyellow)
  for i = 1,#music.passage do
    love.graphics.line(0 + imageWidth*(music.bars[music.passage[i]]/music.duration) , 0 , 0 + imageWidth*(music.bars[music.passage[i]]/music.duration), FONT_HEIGHT)
  end

  -- draw 1st bar, calculated bars based on average tempo
  love.graphics.setColor(color.brightyellow)
  love.graphics.line(0 + imageWidth*(music.barFirst/music.duration) , 5*FONT2X_HEIGHT , 0 + imageWidth*(music.barFirst/music.duration), 6*FONT2X_HEIGHT)
  love.graphics.setColor(color.brightcyan)

  local barsInSong = (math.floor((game.music:getDuration() - music.barFirst) / ((60/music.tempoAverage)*music.beatsPerBar)))
  -- game.music:getDuration() - music.barFirst = (duration of song left to map)
  -- duration of 1 bar = (60/music.tempoAverage)*music.beatsPerBar
  -- number of bars in song = math.floor((game.music:getDuration() - music.barFirst) / ((60/music.tempoAverage)*music.beatsPerBar))
  if music.tempoAverage ~= 0 then
    for i = 1, barsInSong do
      love.graphics.line((imageWidth*(music.barFirst/music.duration))+(imageWidth*((i*(((60/music.tempoAverage)*music.beatsPerBar)/music.duration)))), 5*FONT2X_HEIGHT , (imageWidth*(music.barFirst/music.duration))+(imageWidth*((i*(((60/music.tempoAverage)*music.beatsPerBar)/music.duration)))), 6*FONT2X_HEIGHT)
    end
  end

  -- draw beats per bar when music is playing, and there is an average tempo calculated (need patching)
--  if music.barTimeElapsed ~= 0 and music.tempoAverage ~= 0 then
--    if music.barTimeElapsed > 3*(60/music.tempoAverage) then
--      love.graphics.print(music.barTimeElapsed .. "\nCurrent beat in bar   : 1 ... 2 ... 3 ... 4 ...", 0, 12*FONT2X_HEIGHT)
--    elseif music.barTimeElapsed > 2*(60/music.tempoAverage) then
--      love.graphics.print(music.barTimeElapsed .. "\nCurrent beat in bar   : 1 ... 2 ... 3 ...", 0, 12*FONT2X_HEIGHT)
--    elseif music.barTimeElapsed > 1*(60/music.tempoAverage) then
--      love.graphics.print(music.barTimeElapsed .. "\nCurrent beat in bar   : 1 ... 2 ...", 0, 12*FONT2X_HEIGHT)
--    else
--      love.graphics.print(music.barTimeElapsed .. "\nCurrent beat in bar   : 1 ...", 0, 12*FONT2X_HEIGHT)
--    end
--  end

  -- draw Piano 13 keys
  love.graphics.setFont(monoFont)
  love.graphics.setColor(color.white)
  love.graphics.print(xtui["piano-13"], 0, 10*FONT_HEIGHT)


  -- draw last so that it is on top of everything
  if selected.menuRow ~= 0 then
    drawMenu()
  end

end

function love.update(dt)
  -- Your game update here

  if game.music:isPlaying() then
    music.barTimeElapsed = music.barTimeElapsed + dt
  else
    music.barTimeElapsed = 0
  end

  -- mouse button detections
  if love.mouse.isDown(1) and selected.textmode == 2 and game.mode == "edit" then
    if (game.mousex >= 1 and game.mousex <= game.canvasx) and (game.mousey >= 1 and game.mousey <= game.canvasy) then
      -- move game cursor
      game.cursorx = game.mousex
      game.cursory = game.mousey
      -- store selected in ansiArt
      ansiArt[game.mousey][(game.mousex*2)-1] = selected.color
      ansiArt[game.mousey][game.mousex*2] = selected.char
    end
  end

  if love.mouse.isDown(1) and selected.textmode == 1 and game.mode == "edit" then
    if (game.mousex >= 1 and game.mousex <= game.canvasx) and (game.mousey >= 1 and game.mousey <= game.canvasy*2) then
      -- move game cursor
      game.cursorx = game.mousex
      game.cursory = game.mousey
      -- store selected in ansiArt
      ansiArt[math.ceil(game.mousey/2)][(game.mousex*2)-1] = selected.color
      ansiArt[math.ceil(game.mousey/2)][game.mousex*2] = selected.char
    end
  end

  -- game timers
  game.timeThisSession = game.timeThisSession + dt
  game.autosaveCooldown = game.autosaveCooldown - dt
  if game.autosaveCooldown < 0 then
    game.autosaveCooldown = 0
  end

  -- set pulsing effect color
  if math.floor(game.timeThisSession)%2 == 1 then
    -- odd seconds
    color.pulsingwhite = {(game.timeThisSession%1),(game.timeThisSession%1),(game.timeThisSession%1),1} -- using modulo for fading alpha channel
  else
    -- even seconds
    color.pulsingwhite = {1-(game.timeThisSession%1),1-(game.timeThisSession%1),1-(game.timeThisSession%1),1} -- using modulo for fading alpha channel
  end

  -- set mouse coords
  game.mousex = math.floor(love.mouse.getX()/8)+1 -- coords in font2x starting at 1x1
  game.mousey = math.floor(love.mouse.getY()/8)+1 -- coords in font2x starting at 1x1

  -- autosave every minute
  if math.ceil(game.timeThisSession)%60 == 0 and game.autosaveCooldown == 0 then
    -- every 60 seconds
    game.autosaveCooldown = 3 -- 3 seconds cooldown
--    local files = love.filesystem.getDirectoryItems( "autosave" )
--    saveData("autosave_"..(#files)..".xtui","autosave") -- running numbers for quicksaves
  end

  -- set statusbar
  game.statusbar = game.cursorx..","..game.cursory.." ("..game.mousex..","..game.mousey..") Time:"..math.floor(game.timeThisSession)
  if game.os ~= "R36S" then
    -- statusbar for all other platforms
    game.statusbar = game.statusbar .. " ["..game.os.."] | " .. game.mode .. " | Insert:" .. tostring(game.insertMode)
  else
    -- statusbar for R36S
    game.statusbar = game.statusbar .. " ["..game.os.."] L1:Change Color R1:Change Viewport"
  end

end

function love.keypressed(key, scancode, isrepeat)

  -- Inputs for "TempoMapper"
  if game.scene == "TempoMapper" then
    game.inputTips = "" -- init inputTips

    -- use Spacebar to mark bars in a passage (1st beats) and store in table music.bars
    game.inputTips = game.inputTips .. "space : mark the 1st beat of a bar\n"
    if key == "space" and game.music:isPlaying() then
      if music.barFirst == 0 then
        -- first beat entry, assume 1st beat of 1st bar
        music.barFirst = music.position
      elseif music.position < music.barFirst then
        -- earlier bar entry detected, update music.barFirst
        music.barFirst = music.position
      end
      table.insert(music.bars, music.position)
      music.beatCurrent = 1
      music.barTimeElapsed = 0
    end

    -- "W" to clear music.bars
    game.inputTips = game.inputTips .. "w : clear music bars data\n"
    if key == "w" then
      music.bars = {}
      music.tempoAverage = 0
      music.tempoCurrent = 0
      music.barFirst = 0
      music.barLast = 0
    end
    -- "S" to quit app
    game.inputTips = game.inputTips .. "s : start or pause music\n"
    if key == "s" then
      if game.music:isPlaying() then
        game.music:pause()
        table.sort(music.bars) -- sort bars before saving
      --  saveData(fileName, "data", music) -- need to patch the filename part
      else
        game.music:play()
      end
    end
    -- "A" to quit app
    game.inputTips = game.inputTips .. "a : move back 2 seconds\n"
    if key == "a" then
      if music.position - 2 >= 0 then
        music.position = music.position - 2
        game.music:seek(music.position)
      else
        music.position = 0
        game.music:seek(music.position)
      end
    end
    -- "D" to quit app
    game.inputTips = game.inputTips .. "d : move forward 2 seconds\n"
    if key == "d" then
      if music.position + 2 <= game.music:getDuration() then
        music.position = music.position + 2
        game.music:seek(music.position)
      else
        music.position = game.music:getDuration()
        game.music:seek(music.position)
      end
    end

    -- "Up" to play piano note 28
    game.inputTips = game.inputTips .. "Up : Play note - C\n"
    if key == "up" then
      if piano[28]:isPlaying() then
        piano[28]:stop()
      end
      piano[28]:play()
    end
    -- "Left" to play piano note 29
    game.inputTips = game.inputTips .. "Left : Play note - C#\n"
    if key == "left" then
      if piano[29]:isPlaying() then
        piano[29]:stop()
      end
      piano[29]:play()
    end
    -- "Down" to play piano note 30
    game.inputTips = game.inputTips .. "Down : Play note - D\n"
    if key == "down" then
      if piano[30]:isPlaying() then
        piano[30]:stop()
      end
      piano[30]:play()
    end
    -- "Right" to play piano note 31
    game.inputTips = game.inputTips .. "Right : Play note - D#\n"
    if key == "right" then
      if piano[31]:isPlaying() then
        piano[31]:stop()
      end
      piano[31]:play()
    end
    -- "T" to play piano note 32
    game.inputTips = game.inputTips .. "T : Play note - E\n"
    if key == "t" then
      if piano[32]:isPlaying() then
        piano[32]:stop()
      end
      piano[32]:play()
    end
    -- "F" to play piano note 33
    game.inputTips = game.inputTips .. "F : Play note - F\n"
    if key == "f" then
      if piano[33]:isPlaying() then
        piano[33]:stop()
      end
      piano[33]:play()
    end
    -- "G" to play piano note 34
    game.inputTips = game.inputTips .. "G : Play note - F#\n"
    if key == "g" then
      if piano[34]:isPlaying() then
        piano[34]:stop()
      end
      piano[34]:play()
    end
    -- "H" to play piano note 35
    game.inputTips = game.inputTips .. "H : Play note - G\n"
    if key == "h" then
      if piano[35]:isPlaying() then
        piano[35]:stop()
      end
      piano[35]:play()
    end
    -- "I" to play piano note 36
    game.inputTips = game.inputTips .. "I : Play note - G#\n"
    if key == "i" then
      if piano[36]:isPlaying() then
        piano[36]:stop()
      end
      piano[36]:play()
    end
    -- "J" to play piano note 37
    game.inputTips = game.inputTips .. "J : Play note - A\n"
    if key == "j" then
      if piano[37]:isPlaying() then
        piano[37]:stop()
      end
      piano[37]:play()
    end
    -- "K" to play piano note 38
    game.inputTips = game.inputTips .. "K : Play note - A#\n"
    if key == "k" then
      if piano[38]:isPlaying() then
        piano[38]:stop()
      end
      piano[38]:play()
    end
    -- "L" to play piano note 39
    game.inputTips = game.inputTips .. "L : Play note - B\n"
    if key == "l" then
      if piano[39]:isPlaying() then
        piano[39]:stop()
      end
      piano[39]:play()
    end

    -- "escape" to quit app
    game.inputTips = game.inputTips .. "esc : quit the app\n"
    if key == "escape" then
      love.event.quit()
    end

  end

  print("key:"..key.." scancode:"..scancode.." isrepeat:"..tostring(isrepeat))

  if key == "escape" and love.system.getOS() ~= "Web" and game.insertMode == false then
    -- love.event.quit()
    -- with steam deck desktop mode, it's too easy to trigger "escape"
    -- use a menu option or a click area to quit
  end


  -- steam deck desktop mode inputs

  -- "escape" START or B button showing menu
  if key == "escape" then
    selected.menuRow = 1
    selected.menuOption = 2
  end

  -- move menu selection after escape is pressed
  if selected.menuRow ~= 0 then
    if key == "up" and selected.menuOption > 2 then
      selected.menuOption = selected.menuOption - 1
    end
    if key == "down" and selected.menuOption < #menuTable[selected.menuRow] then
      selected.menuOption = selected.menuOption + 1
    end
    if key == "left" and selected.menuRow > 1 then
      selected.menuRow = selected.menuRow - 1
      selected.menuOption = 2
    end
    if key == "right" and selected.menuRow < #menuTable then
      selected.menuRow = selected.menuRow + 1
      selected.menuOption = 2
    end
  end

  -- "lshift" button L4 for quicksave
  if key == "lshift" then
    local files = love.filesystem.getDirectoryItems( "quicksave" )
    saveData("quicksave_"..(#files)..".xtui","quicksave") -- running numbers for quicksaves
    game.message = "Quicksaved - " .. "quicksave_"..(#files)..".xtui"
  end

  -- R4 button "pageup" + arrow keys to change canvas size
  if love.keyboard.isDown("pageup") then
    -- arrow keys to select char
    if key == "up" and game.canvasy > 1 then
      game.canvasy = game.canvasy - 1
    end
    if key == "down" and game.canvasy < 60 then
      game.canvasy = game.canvasy + 1
    end
    if key == "left" and game.canvasx > 1 then
      game.canvasx = game.canvasx - 1
    end
    if key == "right" and game.canvasx < 80 then
      game.canvasx = game.canvasx + 1
    end
  end

  -- "tab" to change textmode
  if key == "tab" then
    if selected.textmode == 2 then
      selected.textmode = 1
      print(game.cursory)
      game.cursory = (game.cursory * 2) - 1
      print(game.cursory)
    else
      selected.textmode = 2
      print(game.cursory)
      game.cursory = math.ceil(game.cursory / 2)
      print(game.cursory)
    end
  end

  -- "lalt + arrows" to select char
  if love.keyboard.isDown("lalt") then
    -- arrow keys to select char
    if key == "up" and game.chary > 1 then
      game.chary = game.chary - 1
      selected.char = charTable[game.chary][game.charx]
    end
    if key == "down" and game.chary < 17 then
      game.chary = game.chary + 1
      selected.char = charTable[game.chary][game.charx]
    end
    if key == "left" and game.charx > 1 then
      game.charx = game.charx - 1
      selected.char = charTable[game.chary][game.charx]
    end
    if key == "right" and game.charx < 11 then
      game.charx = game.charx + 1
      selected.char = charTable[game.chary][game.charx]
    end
  end

  -- input while textmode == 2
  if selected.textmode == 2 then

    -- move cursor when R1 ("lalt") is not held and not menu selection
    if not(love.keyboard.isDown("lalt")) and selected.menuRow == 0 then
      if key == "up" and game.cursory > 1 then
        game.cursory = game.cursory - 1
      end
      if key == "down" and game.cursory < game.canvasy then
        game.cursory = game.cursory + 1
      end
      if key == "left" and game.cursorx > 1 then
        game.cursorx = game.cursorx - 1
      end
      if key == "right" and game.cursorx < game.canvasx then
        game.cursorx = game.cursorx + 1
      end
    end

    -- draw char at cursor
    if key == "return" and game.message == "" then
      ansiArt[game.cursory][(game.cursorx*2)-1] = selected.color
      ansiArt[game.cursory][game.cursorx*2] = selected.char
    end

  end

  -- input while textmode == 1
  if selected.textmode == 1 then

    -- move cursor when R1 ("lalt") is not held, and not menu selection
    if not(love.keyboard.isDown("lalt")) and selected.menuRow == 0 then
      if key == "up" and game.cursory > 1 then
        game.cursory = game.cursory - 2
      end
      if key == "down" and game.cursory < ((game.canvasy-1)*2) then
        game.cursory = game.cursory + 2
      end
      if key == "left" and game.cursorx > 1 then
        game.cursorx = game.cursorx - 1
      end
      if key == "right" and game.cursorx < (game.canvasx) then
        game.cursorx = game.cursorx + 1
      end
    end

    -- draw char at cursor
    if key == "return" and game.message == "" then
      ansiArt[math.ceil(game.cursory/2)][(game.cursorx*2)-1] = selected.color
      ansiArt[math.ceil(game.cursory/2)][game.cursorx*2] = selected.char
    end

  end



  -- use A button "return" to clear game messages
  if game.message ~= "" then
    if key == "return" then
      game.message = ""
    end
  end

end

function love.mousepressed( x, y, button, istouch, presses )
  local mouse = {
    x = math.floor(love.mouse.getX()/8)-79,
    y = math.floor(love.mouse.getY()/8)-4
  }

  -- set game message based on click heatmap
  game.message = click[game.mousex][game.mousey]

  if mouse.y >= 1 and mouse.y <= 8 then -- first bright palette row
    if mouse.x == 63 or mouse.x == 64 then -- black
      selected.color = color.black
    end
    if mouse.x == 65 or mouse.x == 66 then -- bright red
      selected.color = color.brightred
    end
    if mouse.x == 67 or mouse.x == 68 then -- bright yellow
      selected.color = color.brightyellow
    end
    if mouse.x == 69 or mouse.x == 70 then -- bright green
      selected.color = color.brightgreen
    end
    if mouse.x == 71 or mouse.x == 72 then -- bright cyan
      selected.color = color.brightcyan
    end
    if mouse.x == 73 or mouse.x == 74 then -- bright blue
      selected.color = color.brightblue
    end
    if mouse.x == 75 or mouse.x == 76 then -- bright magenta
      selected.color = color.brightmagenta
    end
    if mouse.x == 77 or mouse.x == 78 then -- white
      selected.color = color.white
    end
  end
  if mouse.y >= 9 and mouse.y <= 16 then -- first dark palette row
    if mouse.x == 63 or mouse.x == 64 then -- black
      selected.color = color.black
    end
    if mouse.x == 65 or mouse.x == 66 then -- red
      selected.color = color.red
    end
    if mouse.x == 67 or mouse.x == 68 then -- yellow
      selected.color = color.yellow
    end
    if mouse.x == 69 or mouse.x == 70 then -- green
      selected.color = color.green
    end
    if mouse.x == 71 or mouse.x == 72 then -- cyan
      selected.color = color.cyan
    end
    if mouse.x == 73 or mouse.x == 74 then -- blue
      selected.color = color.blue
    end
    if mouse.x == 75 or mouse.x == 76 then -- magenta
      selected.color = color.magenta
    end
    if mouse.x == 77 or mouse.x == 78 then -- darkgrey
      selected.color = color.darkgrey
    end
  end

  if mouse.x >= 63 then
    if (mouse.y >= 1 and mouse.y <= 2) or (mouse.y >= 9 and mouse.y <= 10) then -- full block
      selected.char = "█"
    end
    if (mouse.y >= 3 and mouse.y <= 4) or (mouse.y >= 11 and mouse.y <= 12) then -- full block
      selected.char = "▓"
    end
    if (mouse.y >= 5 and mouse.y <= 6) or (mouse.y >= 13 and mouse.y <= 14) then -- full block
      selected.char = "▒"
    end
    if (mouse.y >= 7 and mouse.y <= 8) or (mouse.y >= 15 and mouse.y <= 16) then -- full block
      selected.char = "░"
    end
  end

  -- mouse clicked in drawing area
--  if (game.mousex >= 1 and game.mousex <= game.canvasx) and (game.mousey >= 1 and game.mousey <= game.canvasy) then
--    ansiArt[game.mousey][(game.mousex*2)-1] = selected.color
--    ansiArt[game.mousey][game.mousex*2] = selected.char
--  end

end

function love.touchpressed(id, x, y, dx, dy, pressure)
end


function love.filedropped(file)
  if file then
    initMusic()
    music.filename = file:getFilename()
    file:open("r")
    local fileData = file:read("data")
    music.audioData = love.sound.newSoundData(fileData)
    music.sampleRate = music.audioData:getSampleRate()
    music.channels = music.audioData:getChannelCount()
	  music.duration = music.audioData:getDuration()
	  -- load the audio file for playback
	  game.music = love.audio.newSource(music.audioData, "stream")
    -- Create an image to draw the waveform
    imageWidth, imageHeight = 640, 48
    music.waveData = love.image.newImageData(imageWidth, imageHeight)
    music.waveform = love.graphics.newImage(music.waveData)
    -- Generate the waveform
    generateWaveform(imageWidth,imageHeight)

    file:close()
  end
end


--[[ To-Dos
  * export to PNG
  * auto-convert JPG PNG to XTUI
]]

--[[ Changelog
  2025-03-31
  * Implemented using XTUI images (prerendered) instead of code for the UI
  * Implemented color palette, click to select color and shade
  * Implemented ansiart size - 16x16
]]


