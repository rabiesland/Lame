local package = {}

package.config = [[/
;
?]]
_G.loaded = {}
package.loaded = {}
package.path = "./?.lua;./?/init.lua"

function package.searchpath(name,path,sep,rep)
	local conf = package.config:replace("\r",""):split("\n")
	if not sep then
		sep = "."
	end
	if not rep then
		rep = conf[1]
	end
	local pathSplit = package.path:replace("./",path):split(sep)
	local tried = {}
	for _,v in ipairs(pathSplit) do
		local p = v:replace(conf[3],name:replace(sep,rep))
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
		if loaded[name] then
			return loaded[name], ":preload:"
		end
		return "Module doesn't exist in module cache!"
	end,
	function(name)
		local path,code,err = package.searchpath(name,CWD)
		if path then
			local f = files.open(path,"r")
			local dat = f.read("a")
			f.close()
			local l, err = load(dat,path,globals)
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