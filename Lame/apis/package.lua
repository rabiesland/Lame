local package = {}

package.config = [[/
;
?]]
_G.loaded = {}
package.loaded = {}
package.path = _SYSTEM_DISK..":Lame/lib/?.lua;./?.lua;./?/init.lua"

function package.searchpath(name,path,sep,rep)
	local conf = package.config:gsub("\r",""):split("\n")
	if not sep then
		sep = "."
	end
	if not rep then
		rep = conf[1]
	end
	apiAssert(type(name) == "string","Name has to be a string!")
	apiAssert(type(path) == "string","Path has to be a string!")
	apiAssert(type(sep) == "string","Package seperator has to be a string!")
	apiAssert(type(rep) == "string","Path seperator has to be a string!")
	local pathSplit = package.path:gsub("./",path):split(sep)
	local tried = {}
	for _,v in ipairs(pathSplit) do
		local p = v:gsub(conf[3],name:gsub(sep,rep))
		if files.isFile(p) then
			local suc,resp = pcall(files.open(p))
			if suc then
				resp.close()
				return p
			end
		end
		table.insert(tried,p)
	end
	return nil, "ENOENT", "Tried paths "..table.concat(tried,", ")
end

package.searchers = {
	function(name)
		apiAssert(type(name) == "string","Name has to be a string!")
		if loaded[name] then
			return loaded[name], ":preload:"
		end
		return "Module doesn't exist in module cache!"
	end,
	function(name)
		apiAssert(type(name) == "string","Name has to be a string!")
		local path,code,err = package.searchpath(name,CWD)
		if path then
			local f = files.open(path,"r")
			local dat = f.read("a")
			f.close()
			local l, err = load(dat,path,"bt",globals)
			if l then
				return l
			else
				return err
			end
		else
			return err
		end
	end
}

return "package", package