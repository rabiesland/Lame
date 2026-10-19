local l = {}

function l.makeReplaceSafe(str)
	return str:gsub("%%","%%%%"):gsub("%.","%%."):gsub("%+","%%+"):gsub("%$","%%$"):gsub("%-","%%-"):gsub("%^","%%^")
end
function l.makeMatchSafe(str)
	return l.makeReplaceSafe(str):gsub("*","(.*)")
end

function l.getCurDisk()
	local a = CWD:split(":")
	table.remove(a)
	return table.concat(a,":")
end
function l.setCurDisk(d)
	local a = CWD:split(":")
	local path = table.remove(a)
	CWD = fs.resolve(d..":"..path)
	return 
end
function l.getCurPath(d)
	local a = CWD:split(":")
	local path = table.remove(a)
	return path
end
function l.setCurDisk(d)
	return fs.resolve(l.getCurDisk()..":"..d)
end

return l