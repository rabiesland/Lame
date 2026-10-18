local fs = {}

--main api
function fs.exists(path)
	local suc,res = pcall(files.exists,path)
	return suc and res
end

function fs.isFile(path)
	local suc,res = pcall(files.isFile,path)
	return suc and res
end

function fs.isDir(path)
	local suc,res = pcall(files.isDir,path)
	return suc and res
end

function _G.parentOfPathExists(path)
	path = fs.resolve(path)
	local parts = path:split("/")
	if #parts == 1 then
		return false
	end
	local last = parts[1]
	table.remove(parts)
	table.remove(parts,1)
	for _,v in ipairs(parts) do
		if not fs.isDir(last.."/"..v) then
			return false
		end
		last ..= "/"..v
	end
	return true, fs.isDir(last)
end

function fs.list(path)
	if fs.exists(path) then
		if fs.isFile(path) then
			return nil, "ENOENT", "The path is a file!"
		end
		local suc,resp = pcall(files.getChildren,path)
		if not suc then
			return nil, "EIO", resp
		end
		return resp
	end
	return nil, "ENOENT", "The directory doesn't exist!"
end

function fs.makeDir(path)
	local exists, isDir = parentOfPathExists(path)
	if not exists then
		return nil, "ENOENT", "Parent doesn't exist!"
	elseif not isDir then
		return nil, "ENOTDIR", "Parent is a file!"
	end
	if fs.exists(path) then
		return nil, "EEXIST", "Path already exists!"
	end
	local suc,err = pcall(files.makeDir,path)
	if not suc then
		return nil, "EIO", err
	end
	return true
end

function fs.delete(path)
	if not fs.exists(path) then
		return nil, "ENOENT", "Path doesn't exist!"
	end
	if #(path:split("/")) == 1 then
		return nil, "EPERM", "Can't delete root!"
	end
	if not parentOfPathExists(path) then --check twice
		return nil, "EPERM", "Can't delete root!"
	end
	if fs.isDir(path) and #fs.list(path) ~= 0 then
		return nil, "ENOTEMPTY", "Directory not empty!"
	end
	local suc,err = pcall(files.delete,path)
	if not suc then
		return nil, "EIO", err
	end
	return true
end

function fs.resolve(path)
	if path:sub(1,2) == "./" then
		path = CWD..path:sub(3)
	end
	local s = path:split(":")
	local path = s[#s]:gsub(":","")
	if #s == 1 then
		s = _SYSTEM_DISK:split("/")[0]:split(":")
		table.insert(s,path)
	end
	if #s == 2 then
		table.insert(s,1,"0")
	end
	local disk = tonumber(s[1])
	local part = s[2]
	if disk then
		disk = files.getDiskID(disk):sub(28,36)
	elseif s[1] == "any" then
		for _,i in ipairs(files.getDisks()) do
			if files.exists(part..":"..path,i) then
				disk = files.getDiskID(i):sub(28,36)
				break
			end
		end
		if not disk then
			return nil, "ENODEV", "Can't resolve disk from wildcard path"
		end
	else
		disk = s[1]
	end
	local newPathAlmost = path:split("/")
	local newPath = {}
	for _,v in pairs(newPathAlmost) do
		if v == ".." then
			table.remove(newPath)
		elseif v ~= "." and v~="" then
			table.insert(newPath,v)
		end
	end
	return disk..":"..part..":/"..table.concat(newPath,"/")
end

function fs.rename(from,to) --doesn't work yet
	from = fs.resolve(from)
	to = fs.resolve(to)
	local exists, isDir = parentOfPathExists(from)
	if not exists then
		return nil, "ENOENT", "Parent 1 doesn't exist!"
	elseif not isDir then
		return nil, "ENOTDIR", "Parent 1 is a file!"
	end
	if fs.exists(from) then
		return nil, "EEXIST", "Path 1 already exists!"
	end
	
	local exists, isDir = parentOfPathExists(to)
	if not exists then
		return nil, "ENOENT", "Parent 2 doesn't exist!"
	elseif not isDir then
		return nil, "ENOTDIR", "Parent 2 is a file!"
	end
	if fs.exists(to) then
		return nil, "EEXIST", "Path 2 already exists!"
	end
	
	local suc,err = pcall(files.move,from,to) --doesn't exist yet and I'm not making a recursive function to read and copy every file in a dir for a temp fix
	if not suc then
		return nil, "EIO", err
	end
	
	return true
end

function fs.stat(path)
	if fs.exists(path) then
		return {
			type = fs.isFile(path) and "file" or "dir"
		}
	end
	return nil, "ENOENT", "File doesn't exist!"
end

fs.getDisks = files.getDisks

function fs.getPartitions(disk1)
	local disk = tonumber(disk1)
	if not disk then
		for _,i in ipairs(files.getDisks()) do
			if disk1 == files.getDiskID(i):sub(28,36) then
				disk = i
				break
			end
		end
	end
	if not disk then
		return nil, "EINVAL", "Disk doesn't exist!"
	end
	local exists = pcall(files.getDiskID,disk)
	if not exists then
		return nil, "ENODEV", "Disk doesn't exist!"
	else
		local suc,ret = pcall(files.getPartitions,exists)
		if not suc then
			return nil, "EIO", ret
		end
		return ret
	end
end

local point = {
	["system.root"] = fs.resolve(_SYSTEM_DISK..":/"),
	["user.home"] = fs.resolve(_SYSTEM_DISK..":/"),
	["system.boot"] = fs.resolve(_SYSTEM_DISK..":/Lame/"),
	
	["system.libraries"] = true,
	["software.local"] = true,
	["software.localData"] = true,
	["software.data"] = true,
	["storage.persistent"] = true,
	["system.config"] = true,
	["system.source"] = true,
	["system.bin"] = true,
	["system.sbin"] = true,
}

function fs.getPoint(p)
	if point[p] == true then
		return fs.resolve(CWD)
	elseif point[p] then
		return point[p]
	end
	return nil
end

function fs.getPoints()
	return {
		["system.root"] = fs.resolve(_SYSTEM_DISK..":/"),
		["user.home"] = fs.resolve(_SYSTEM_DISK..":/"),
		["system.boot"] = fs.resolve(_SYSTEM_DISK..":/Lame/"),
	}
end

--handle shit
local handle = {}

function handle.read(self,amt)
	local f = rawget(self,"__Real_Handle")
	local m = rawget(self,"__File_Mode")
	local c = rawget(self,"__CLOSED")
	if type(amt) ~= "number" and (amt ~= "a" and amt ~= "l") then
		return nil, "EINVAL", "Bad read amount"
	end
	if m ~= "r" then
		return nil, "EBADF", "Cannot read write handle"
	end
	if c then
		return nil, "EIO", "Handle closed!"
	end
	local suc,dat = pcall(f.read,amt)
	if not suc then
		return nil,"EIO",dat
	end
	return dat
end

function handle.write(self,dat)
	local f = rawget(self,"__Real_Handle")
	local m = rawget(self,"__File_Mode")
	local c = rawget(self,"__CLOSED")
	if m ~= "w" then
		return nil, "EBADF", "Cannot write read handle"
	end
	if c then
		return nil, "EIO", "Handle closed!"
	end
	local suc,err = pcall(f.write,dat)
	if not suc then
		return nil,"EIO",err
	end
	return self
end

function handle.seek(self,w,o)
	local f = rawget(self,"__Real_Handle")
	local c = rawget(self,"__CLOSED")
	if c then
		return nil, "EIO", "Handle closed!"
	end
	if not w and not o then
		local suc,pos = pcall(f.seek)
		if not suc then
			return nil,"EIO",pos
		end
		return pos
	end
	if (w == "set" or w == "end") and o < 0 then
		return nil, "ERANGE", "Can't seek outside of file range!"
	end

	local suc,pos =  pcall(f.seek,w,o)
	if not suc then
		return nil,"EIO",pos
	end
	return pos
end

function handle.flush(self)
	local f = rawget(self,"__Real_Handle")
	local c = rawget(self,"__CLOSED")
	if c then
		return nil, "EIO", "Handle closed!"
	end
	local suc,err =  pcall(f.flush)
	if not err then
		return nil,"EIO",err
	end
	return true
end

function handle.close(self)
	local f = rawget(self,"__Real_Handle")
	local c = rawget(self,"__CLOSED")
	if c then
		return nil, "EIO", "Handle already closed!"
	end
	local suc,err =  pcall(f.close)
	if not err then
		return nil,"EIO",err
	end
	rawset(self,"__CLOSED",true)
	rawset(self,"__Real_Handle",nil)
	return true
end

local handlemeta = {
	__index = function(k)
		return rawget(handle,k)
	end,
	__newindex = function(k,v)
		return nil
	end
}
local function createFakeHandle(handle,mode)
	return setmetatable({__Real_Handle=handle,__File_Mode=mode},table.copy(handlemeta))
end

function fs.open(path,m)
	m = m:sub(1,1)
	if m ~= "r" and m ~= "r" and m ~= "a" then
		return nil, "EINVAL", "Invalid mode!"
	end
	if m == "w" or m == "a" then
		local exists, isDir = parentOfPathExists(path)
		if not exists then
			return nil, "ENOENT", "Parent doesn't exist!"
		elseif not isDir then
			return nil, "ENOTDIR", "Parent is a file!"
		end
	else
		if not fs.exists(path) then
			return nil, "ENOENT", "Tried to read non-existant file!"
		end
	end
	if fs.isDir(path) then
		return nil, "EISDIR", "Path is directory!"
	end
	local suc,handle =  pcall(files.open,path,m.."b")
	if not suc then
		return nil,"EIO",handle
	end
	return createFakeHandle(handle,m)
end

return "fs", fs