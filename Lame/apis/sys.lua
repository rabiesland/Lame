local sys = {}

function sys.getOSName()
	return "Lame"
end

function sys.getOSVersion()
	return _G.LAMEVERSION
end

function sys.getExtensions()
	return table.copy(_G.NEATOAPIS)
end

function sys.hasExtension(ext,ver)
	apiAssert(ext ~= nil and type(ext) == "string", "Extension has to be string!")
	apiAssert(ver == nil or type(ver) == "number", "Version has to be number!")
	if not ver then
		ver = _G.NEATOAPIS[ext]
	end
	if _G.NEATOAPIS[ext] and _G.NEATOAPIS[ext] == ver then
		return true
	end
	return false
end

function sys.sleep(t)
	apiAssert(t == nil or (type(t) == "number" and t >= 0), "Invalid time argument!")
	sleep(t)
end

return "sys", sys