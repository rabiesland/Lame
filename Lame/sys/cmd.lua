local defaultAliases = {
	"chdir="..env.get("root")..":Lame/sys/cd.lua",
	"clr="..env.get("root")..":Lame/sys/clear.lua",
	"erase="..env.get("root")..":Lame/sys/del.lua",
	"md="..env.get("root")..":Lame/sys/mkdir.lua",
	"ren="..env.get("root")..":Lame/sys/rename.lua",
	"rd="..env.get("root")..":Lame/sys/del.lua"
}
if not env.get("alias") then
	env.set("alias",table.concat(defaultAliases,";"))
end

local l = require("lamecoreutilhelper")

local function fileExists(path)
	if fs.isFile(path) then
		return path
	elseif fs.isFile(path..".lua") then
		return path..".lua"
	elseif fs.isFile(path..".bat") then
		return path..".bat"
	end
	return nil
end

local function resolveProgramPath(path)
	local f = fileExists(path) or fileExists(CWD.."/"..path)
	if f then
		return f
	end
	for i,v in pairs(os.getenv("path"):split(";")) do
		if fileExists(v.."/"..path) then
			return fileExists(v.."/"..path)
		end
	end
end

local function aliasExists(path)
	local alias = os.getenv("alias"):split(";")
	for _,v in ipairs(alias) do
		local split = v:split("=")
		if split[1] == path and split[2] then
			return split[2]
		end
	end
end
local runBatch
local function runCommand(i)
	if i:sub(#i,#i) == ":" then
		local s,e = pcall(function()
			if fs.isDir(i.."/") then
				l.setCurDisk(i:sub(1,#i-1))
			else
				print("Invalid device "..i:upper())
			end
		end)
		if not s then
			print("Invalid device "..i:upper())
		end
		return
	end
	local i1 = i
	for m in i1:gmatch("%%(.*)%%") do
		log(m)
		local val = os.getenv(m) or ""
		val = val:gsub("%%","%%%%")
		i = i:gsub("%%"..l.makeReplaceSafe(m).."%%",val)
	end
	local sp1 =  i:split(" ")
	local sp = {}
	local last = ""
	local quoted = false
	for _,v in ipairs(sp1) do
		if quoted then
			if v:sub(-1) == '"' then
				quoted = false
				table.insert(sp,last.." "..v:sub(1,-2))
				last = ""
			else
				last ..= " "..v
			end
		else
			if v:sub(1,1) == '"' then
				if v:sub(-1) == '"' then
					table.insert(sp,v:sub(2,-2))
				else
					quoted = true
					last = v:sub(2)
				end
			else
				table.insert(sp,v)
			end
		end
	end
	if quoted then
		table.insert(sp,last)
	end
	local prog = table.remove(sp,1)
	if not prog then
		return
	end
	local progPath = resolveProgramPath(prog:lower())
	local alias = aliasExists(prog:lower())
	if not progPath and alias then
		local suc, err = pcall(os.execute,alias,table.unpack(sp))
		if not suc then
			print(err)
		end
	elseif not progPath then
		print("Bad command or filename - "..prog)
	else
		if progPath:sub(-4) == ".bat" then
			runBatch(progPath)
		else
			local suc, err = pcall(os.execute,progPath,table.unpack(sp))
			if not suc then
				print(err)
			end
		end
	end
	coroutine.yield()
	local cursorPos = term.getCursorPos()
	if cursorPos ~= 1 then
		print()
	end
end
function runBatch(...)
	local file = table.concat({...}," ")
	if not fs.isFile(file) and fs.isFile(getWorkingPath().."/"..file) then
		file = getWorkingPath().."/"..file
	end
	if not fs.isFile(file) then
		term.print("Batch file doesn't exist!")
		return
	end
	local f = fs.open(file,"r")
	local fdat = f:read("a")
	f:close()
	local lines = fdat:gsub("\r\n","\n"):split("\n")
	local labels = {}
	local i = 1
	while i <= #lines do
		local v = lines[i]
		if v:sub(1,1) == ":" then
			labels[v:sub(2):lower()] = i
			table.remove(lines,i)
			i-=1
		end
		i+=1
	end
	local p = true
	local i = 1
	while i <= #lines do
		local v = lines[i]
		local p1 = p
		if v:sub(1,1) == "@" then
			p1 = false
			v = v:sub(2)
		end
		if v:sub(1,5) == "goto " then
			local label = v:sub(6):lower()
			if labels[label] then
				i = labels[label]
				continue
			end
		end
		if p1 then
			print(CWD.."> "..v)
		end
		if v:lower() == "echo off" then
			p = false
		elseif v:lower() == "echo on" then
			p = true
		else
			runCommand(v)
		end
		i += 1
	end
end
local args = {}
if #args == 0 then
	if not env.get("SHELL_FIRST_RUN") then
		if fs.isFile(env.get("root")..":autoexec.bat") then
			runBatch(env.get("root")..":autoexec.bat")
		end
		env.set("SHELL_FIRST_RUN","FALSE")
	end
	while true do
		event.clear()
		term.write(CWD.."> ")
		runCommand(input())
	end
else
	args = table.concat(args," ")
	if fs.isFile(args) then
		runBatch(args)
	else
		runCommand(args)
	end
end