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
	["setPartitionHidden"] = true
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
				v[1] = s[2]..":"..s[3]
				if threeArgFunc[k] then
					v[3] = tonumber(s[1])
				else
					v[2] = tonumber(s[1])
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
    for i,v in pairs(oldTab) do
        if type(v) ~= "table" then
           tab[i] = v
        elseif i ~= "_G" then
            tab[i] = deepCopyTable(v)
        end
    end
	setmetatable(tab,getmetatable(oldTab))
    return tab
end
_G.table.copy = deepCopyTable

local function sleep(t)
	if t == 0 then
		t = nil
	end
    local start = chip.getUnixTime()
    if not t then
       yield()
    else
        local newTime = chip.getUnixTime()+t
        while chip.getUnixTime() < newTime do
            yield()
        end
    end
    return chip.getUnixTime()-start
end
_G.sleep = sleep

---------------------
-- Loads our APIs. --
---------------------

local globalTable = {}
_G.globals = globalTable

for _,v in pairs(files.getChildren(_SYSTEM_DISK..":Lame/apis")) do
	if files.isFile(_SYSTEM_DISK..":Lame/apis/"..v) then
		local name,api = import(_SYSTEM_DISK..":Lame/apis/"..v)
		globalTable[name] = api
		print("Loaded API "..name.."!")
	end
end

while true do
	coroutine.yield()
end