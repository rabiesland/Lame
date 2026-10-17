return "loadfile", function(path, mode, env)
    if files.exists(path) then
		if files.isFile(path) then
			local datFile = files.open(path,"r")
			local dat = datFile.read("a")
			datFile.close()
			return load(dat,path, mode, env)
		end
		return nil, "EISDIR", "The specified path is a directory."
    end
	return nil, "ENOENT", "The specified path does not exist."
end