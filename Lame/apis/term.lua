-- virtual terminal for Lame, taken from my previous project TRASHY
local sizeX1,sizeY1 = screen.getSize()
local termSizeX, termSizeY = math.floor((sizeX1-1)/8)*8, math.floor((sizeY1-1)/16)*16
local topX, topY = (sizeX1/2)-(termSizeX/2), (sizeY1/2)-(termSizeY/2)
local termTable = table.create((termSizeY/16)*(termSizeX/8))
for i=1,termSizeY/16 do
    local a = table.create(termSizeX/8)
    for i1=1,termSizeX/8 do
        table.insert(a,32)
    end
    table.insert(termTable,a)
end

--the vterm uses a VGA BIOS font taken from here https://github.com/viler-int10h/vga-text-mode-fonts
--it has a limited character set but it SHOULD be in the clear copyright wise since its taken from 80s hardware
--its also era appropriate
local fonTable = table.create(255,1)
local none = string.char(0, 0, 0, 0)
local f = files.open(_SYSTEM_DISK..":Lame/ATI8X16.F16","rb")
for i=0,255 do
	local fnt = {}
	for _=1,16 do
		local lineDat = string.byte(f.read(1))
		for x=0,7 do
			table.insert(fnt,(((lineDat >> 8-x) & 1)~=0 and "#" or none)) --for some reason the font is Big Endian
		end
	end
	if i==0 then
		fonTable[0] = table.concat(fnt)
	else
		table.insert(fonTable,table.concat(fnt))
	end
	
end
f.close()
local function generateFontFromColor(r,g,b,a)
	local color = string.char(r, g, b, a)
	local newFont = table.create(255,1)
	for i,v in pairs(fonTable) do
		local new = v:gsub("#",color)
		if i==0 then
			newFont[0] = new
		else
			table.insert(newFont,new)
		end
	end
	return newFont
end

local bkg = {0,0,0}
local fg = {220,220,220}
local bkgChar = string.char(0, 0, 0, 255)
local bkgSquare = string.char(0, 0, 0, 255):rep(128)
local font = generateFontFromColor(220,220,200,255)

local x,y = 1,1
local sizeX, sizeY = termSizeX/8, termSizeY/16
local vterm = {}
vterm.generateFontFromColor = generateFontFromColor
local function drawChar(x,y,c)
	local charNum = font[c] or font[0]
	screen.writeData(topX+((x-1)*8),topY+((y-1)*16),charNum,8)
end
local function blankChar(x,y)
	screen.writeData(topX+((x-1)*8),topY+((y-1)*16),bkgSquare,8)
end
local emptyColumn = none:rep(8*16*sizeY)
function vterm.draw()
    for x=1,sizeX do
		screen.writeData(topX+((x-1)*8),topY,bkgChar:rep(8*16*sizeY),8)
	end
	for x=1,sizeX do
		local column = {}
		for _,v in ipairs(termTable) do
			table.insert(column,font[v[x]] or font[0])
		end
		local conc = table.concat(column)
		if conc ~= emptyColumn then
			screen.writeData(topX+((x-1)*8),topY,conc,8)
		end
	end
    screen.draw()
end
function vterm.setTextColor(r,g,b)
	apiAssert(type(r) == "number","Red has to be a number!")
	apiAssert(type(g) == "number","Green has to be a number!")
	apiAssert(type(b) == "number","Blue has to be a number!")
	fg = {r,g,b}
	font = generateFontFromColor(r,g,b,255)
	vterm.draw()
end
function vterm.setBackgroundColor(r,g,b)
	apiAssert(type(r) == "number","Red has to be a number!")
	apiAssert(type(g) == "number","Green has to be a number!")
	apiAssert(type(b) == "number","Blue has to be a number!")
	bkg = {r,g,b}
	bkgChar = string.char(r,g,b, 255)
	bkgSquare = string.char(r,g,b, 255):rep(128)
	vterm.draw()
end
function vterm.getTextColor()
	return table.unpack(fg)
end
function vterm.getBackgroundColor()
	return table.unpack(bkg)
end

function vterm.setCursorPos(x1,y1)
	apiAssert(type(x1) == "number","X has to be a number!")
	apiAssert(type(y1) == "number","Y has to be a number!")
    x,y = x1,y1
end

function vterm.getCursorPos()
    return x,y
end

function vterm.getSize()
    return sizeX,sizeY
end

local handleChar = {
	[08] = function() -- Backspace
		x-=1
		if termTable[y][x] then
			local old = termTable[y][x]
			if old ~= 32 then
				blankChar(x,y)
			end
			termTable[y][x] = 0
		end
	end,
	[09] = function() -- Normal Tab
		x+=2
	end,
	[10] = function() -- New Line
		y+=1
		x=1
		if y > sizeY then
			y = sizeY
			vterm.scroll(1);
		end
	end,
	[13] = function() -- Carriage Return
		x=1
	end,
	
	
	[32] = function() -- Space
		if termTable[y][x] then
			blankChar(x,y)
		end
		x+=1
	end
}

function vterm.write(str)
	str = tostring(str)
    local split = {}
    for i=1,#str do
        table.insert(split,str:sub(i,i))
    end
	local buffer = table.create(16)
    for i,v in ipairs(split) do
		local byteChar = string.byte(v)
		if byteChar > 32 and byteChar < 127 then
			if termTable[y][x] then
				local old = termTable[y][x]
				local new = font[byteChar]
				if old ~= 32 and old ~= byteChar then
					blankChar(x,y)
				end
				termTable[y][x] = byteChar
				drawChar(x,y,byteChar)
			end
			x+=1
		elseif handleChar[byteChar] then
			handleChar[byteChar]()
		end
		if x > sizeX and i ~= #split then
			y+=1
			x = 1
			if y > sizeY then
				y = sizeY
				vterm.scroll(1);
			end
		elseif x > sizeX then
			x-=1
		end
    end
    screen.draw()
end

function vterm.scroll(i)
	apiAssert(type(i) == "number","Argument 1 has to be a number!")
    for i1=i, sizeY do
        termTable[i1-i+1] = termTable[i1+1]
    end
    for i1=sizeY-i+1,sizeY do
        local a = table.create(sizeX)
        for i1=1,sizeX do
            table.insert(a,32)
        end
        termTable[i1] = a
    end
    y = y-i
    if y < 1 then
        y = 1;
    end
    vterm.draw()
end

function vterm.clear()
	local newTable = table.create(sizeX*sizeY)
	for i=1,sizeY do
		local a = table.create(sizeX)
		for i1=1,sizeX do
			table.insert(a,32)
		end
		table.insert(newTable,a)
	end
	termTable = newTable
	vterm.draw()
end

function vterm.clearLine()
	local a = {}
	for i=1,sizeX do
		table.insert(a,32)
	end
	termTable[y] = a
	vterm.draw()
end

return "term", vterm
