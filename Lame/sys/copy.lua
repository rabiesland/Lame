local args = {...}
if #args ~= 2 then
	print("Copy requires two arguments to work!")
	return
end
local toProbe = args[1]
local destination = args[2]

local l = require("lamecoreutilhelper")

local function resolveCopyDest(dest)
	local finalDir
	if fs.isDir(dest) then
		finalDir = dest
	else
		finalDir = CWD.."/"..dest
	end
	local split = dest:split("/")
	local m = (table.remove(split) or "")
	local finalDir1 = CWD.."/"..table.concat(split,"/")
	local finalDir2 = table.concat(split,"/")
	if fs.isDir(finalDir) then
		return finalDir, "*"
	elseif fs.isDir(finalDir1) then
		return finalDir1, m
	elseif fs.isDir(finalDir2) then
		return finalDir2, m
	end
	return nil
end

local from, match1 = resolveCopyDest(toProbe)
local to, match2 = resolveCopyDest(destination)
match1 = "^"..l.makeMatchSafe(match1)
match2 = match2:gsub("%%","%%%%")
local starCount = 0
local a = ""
for i=1,#match2 do
	local v = match2:sub(i,i)
	if v == "*" then
		starCount+=1
		a..="%"..starCount
	else
		a..=v
	end
end
match2 = a
if not from or not to then
	print("Copy requires a valid target and destination")
	return
end
local x,y = vterm.getSize()
local function recurse(from,to,match1,match2)
	for _,v in pairs(fs.list(from)) do
		if not v:match(match1) then
			continue
		end
		if fs.isDir(from.."/"..v) then
			if not fs.exists(to.."/"..(v:gsub(match1,match2))) then
				fs.makeDir(to.."/"..(v:gsub(match1,match2)))
			elseif fs.isFile(to.."/"..(v:gsub(match1,match2))) then
				fs.delete(to.."/"..(v:gsub(match1,match2)))
				fs.makeDir(to.."/"..(v:gsub(match1,match2)))
			end
			recurse(from.."/"..v,to.."/"..(v:gsub(match1,match2)),"^(*.*)","%1")
			continue
		end
		local f1 = fs.open(from.."/"..v, "r")
		if fs.exists(to.."/"..(v:gsub(match1,match2))) then
			fs.delete(to.."/"..(v:gsub(match1,match2)))
		end
		print((v:gsub(match1,match2)))
		local f2 = fs.open(to.."/"..(v:gsub(match1,match2)),"w")
		f2:write(f1:read("a"))
		f1:close()
		f2:flush()
		f2:close()
	end
end
recurse(from,to,match1,match2)