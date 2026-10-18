return "input", function(hide)
	apiAssert(type(hide) == "string" or hide == nil, "Hide character has to be a string!")
	local term = mainGlobalTable.term
	local event = mainGlobalTable.event
    local str = ""
    while true do
        local sizeX,sizeY = term.getSize()
        local posX,posY = term.getCursorPos()
        local n,key = event.poll()
        if n == "key" then
            if key == "enter" then
                term.write("\n")
                break
            elseif key == "backspace" then
                if #str ~= 0 then
                    str = str:sub(1,#str-1)
                    posX = posX - 1
                    if posX == 0 then
                        posY = posY - 1
                        posX = sizeX
                    end
                    term.setCursorPos(posX,posY)
                    term.write(" ")
					term.setCursorPos(posX,posY)
                end
            end
		elseif n == "char" then
			if posX > sizeX then
                posX = 1
                posY = posY + 1
                term.setCursorPos(posX,posY)
                if posY > sizeY then
                    term.scroll(1)
                end
            end
			if not hide then
				term.write(key)
			else
				term.write(hide:sub(1,1))
			end
            
            str = str .. key
        end
		coroutine.yield()
    end
    return str
end