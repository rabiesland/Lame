local keyCodes = {
	[8] = "backspace",
	[9] = "tab",
	[13] = "enter",
	[14] = "leftShift",
	[128] = "left",
	[129] = "right",
	[130] = "up",
	[131] = "down",
	[132] = "leftCtrl",
	[133] = "leftAlt",
}
local pressedKeys = {}

function _G.eventToNeato(args)
	local event = table.remove(args,1)
	if event == "keyPressed" then
		local char
		if args[2] then
			char = args[2]
		end
		local name = keyCodes[args[1]] or char:lower() or "x."..args[1]
		local pressed = pressedKeys[args[1]] or false
		pressedKeys[args[1]] = true
		if pressedKeys[132] and name == "t" then
			table.remove(programStack)
			mainGlobalTable.print("Terminated.")
		end
		if char ~= nil then
			return {"key", name, pressed},{"char",char}
		else
			return {"key", name, pressed}
		end
	elseif event == "keyReleased" then
		local name = keyCodes[args[1]] or args[2] or "x."..args[1]
		pressedKeys[args[1]] = nil
		return {"key_up", name}
	end
end

local function getCurrentProgTab()
	local c = coroutine.running()
	for _,v in pairs(programStack) do
		if v.c == c then
			return v
		end
	end
end

local eventApi = {}

function eventApi.clear()
	getCurrentProgTab().e = {}
end

function eventApi.push(...)
	table.insert(getCurrentProgTab().e,{...})
	return true
end

function eventApi.poll()
	local eventTab = getCurrentProgTab().e
	if #eventTab == 0 then
		return nil
	end
	return table.unpack(table.remove(eventTab,1))
end

function eventApi.pull(filter,timeout)
	local eventTab = getCurrentProgTab().e
	local started = chip.getUnixTime()
	while true do
		if timeout then
			if chip.getUnixTime() > started+timeout then
				return nil
			end
		end
		if #eventTab ~= 0 then
			local event = table.remove(eventTab,1)
			if filter == nil or event[1] == filter then
				return table.unpack(event)
			end
		end
		coroutine.yield()
	end
end

return "event", eventApi