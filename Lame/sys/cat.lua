local path = CWD.."/"..table.concat({...}," ")
if fs.isFile(path) then
	local f = fs.open(path,"r")
	print(f:read("a"))
end
