--LAME v1
_G.LAMEVERSION = "1.0"

_G.NEATOAPIS = {
	core = 3
}

print("Early init started!")
local sysDisk = ({...})[1] or "hdd" --assume the bootloader was replaced with a braindead vibecoded implementation that can't pass basic arguments
_G._SYSTEM_DISK = sysDisk

-----------------------------------------------------------------------------------------------------
-- This defines internal functions used internally. Functionally the same as TRASHY's program API. --
-----------------------------------------------------------------------------------------------------

--simplistic version of require since we can't pull require in yet.
local function import(path)
	if files.exists(path) then
		local datFile = files.open(path,"r")
		local dat = datFile.read("a")
		datFile.close()
		local prog,err = load(dat,path)
		if prog then
			local worked = {pcall(prog)}
			if not worked[1] then
				error("Failure while loading program "..path.."! Err="..worked[2]);
			else
				table.remove(worked,1)
				return table.unpack(worked)
			end
		else
			error("Failed to load program "..path.."! Err="..err);
		end
	else
		error("File "..path.." does not exist!")
	end
end
_G.import = import

local function splitStr(i, sep)
	local split = {}
	for m in i:gmatch("([^"..sep.."]+)") do
		table.insert(split,m)
	end
	return split
end
_G.string.split = splitStr

--for neato compliant bootloader support we need neato compliant filesystem support
local oldFiles = files
local newFiles = {}
local newFilesMeta = {}
local threeArgFunc = {
	["open"] = true,
	["setPartitionHidden"] = true,
	["move"] = true --not in NEET but will be soon
}
newFilesMeta.__index = function(_,k)
	if not oldFiles[k] then
		return nil
	end
	return function(...)
		local v = {...}
		if v[1] and type(v[1]) == "string" then
			local s = v[1]:split(":")
			if #s == 3 then
				local disk = tonumber(s[1])
				if not disk then
					if s[1] == "any" then
						for _,i in ipairs(files.getDisks()) do
							if files.exists(part..":"..path,i) then
								disk = i
								break
							end
						end
					else
						for _,i in ipairs(files.getDisks()) do
							if s[1] == files.getDiskID(i):sub(28,36) then
								disk = i
								break
							end
						end
					end
				end
				v[1] = s[2]..":"..s[3]
				if threeArgFunc[k] then
					v[3] = disk
				else
					v[2] = disk
				end
			end
		end
		local suc,err = pcall(oldFiles[k],table.unpack(v))
		if not suc then 
			error(err,2)
		else
			return err
		end
	end
end
setmetatable(newFiles,newFilesMeta)
_G.files = newFiles

--deep copy system to seperate environments
local function deepCopyTable(oldTab)
	local tab = {}
	for k,v in pairs(oldTab) do
		if type(v) ~= "table" then
		   tab[k] = v
		elseif k ~= "_G" then
			tab[k] = deepCopyTable(v)
		end
	end
	local oldm = getmetatable(oldTab)
	if oldm then
		local m = {}
		for k,v in pairs(oldm) do
			if type(v) ~= "table" then
				m[k] = v
			else
				m[k] = deepCopyTable(v)
			end
		end
		setmetatable(tab,m)
	end
	return tab
end
_G.table.copy = deepCopyTable

local function sleep(t)
	if t == 0 then
		t = nil
	end
	local start = chip.getUnixTime()
	if not t then
	   coroutine.yield()
	else
		local newTime = chip.getUnixTime()+t
		while chip.getUnixTime() < newTime do
			coroutine.yield()
		end
	end
	return chip.getUnixTime()-start
end
_G.sleep = sleep

_G.programStack = {}

local function addProgramToStack(...)
	local args = {...}
	local path = table.remove(args,1)
	local datFile = files.open(path,"r")
	local dat = datFile.read("a")
	datFile.close()
	local prog,err = load(dat,path,"bt",globals)
	if prog then
		local worked, progFunc = pcall(coroutine.create,function()
			local success, response = pcall(prog,table.unpack(args))
			if not success then
				globals.print("Program exited with an error! Err="..response)
			end
		end)
		table.insert(programStack,{
			e = {},
			c = progFunc
		})
	else
		error("Failed to load program "..path.."! Err="..err);
	end
end

local cats = {
    "unlabeled",
    "user",
    "system",
    "network",
    "peripheral",
    "compatibility"
}
local function getNextEvent()
    local ret = {}
    for _,v in ipairs(cats) do
         ret[v] = event.getFirst(v)
    end
    return ret
end

--------------------
-- Loads our APIs --
--------------------

_G.CWD = _SYSTEM_DISK..":/"
local globalTable = {}
_G.mainGlobalTable = globalTable

for _,v in pairs(files.getChildren(_SYSTEM_DISK..":Lame/apis")) do
	if files.isFile(_SYSTEM_DISK..":Lame/apis/"..v) then
		local name,api = import(_SYSTEM_DISK..":Lame/apis/"..v)
		globalTable[name] = api
		print("Loaded API "..name.."!")
	end
end

local globals = table.copy(globalTable)
local globalmeta = {
	__index = function(k)
		if k == "CWD" then
			return CWD
		else
			return rawget(globals,k)
		end
	end,
	__newindex = function(k,v)
		if k == "CWD" then
			_G.CWD = CWD
		end
		rawset(globals,k,v)
	end
}
setmetatable(globals,globalmeta)
_G.globals = globals

----------------
-- Event Loop --
----------------

addProgramToStack("hdd:Lame/cmd.lua")

while true do
	local eTable = getNextEvent()
	local neatoEvents = {}
	for _,v in pairs(eTable) do
		local e = {eventToNeato(v)}
		for i=1,#e do
			table.insert(neatoEvents,e[i])
		end
	end
	for _,v in pairs(programStack) do
		for _,v2 in ipairs(neatoEvents) do
			table.insert(v.e,v2)
		end
	end
	local stack = #programStack
	local curProgTab = programStack[stack]
	if not curProgTab then
		while true do
			coroutine.yield()
		end
	end
	local curProgCo = curProgTab.c
	if coroutine.status(curProgCo) == "dead" then
        table.remove(programStack,stack)
    elseif coroutine.status(curProgCo) == "suspended" then
        coroutine.resume(curProgCo)
    end
	if #neatoEvents ~= 0 then
		coroutine.yield()
	end
end