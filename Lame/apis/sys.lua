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
	if not ver then
		ver = math.mininteger
	end
	if _G.NEATOAPIS[ext] and _G.NEATOAPIS[ext] > ver then
		return true
	end
	return false
end

function sys.sleep(t)
	if t and t < 0 then
		return nil, "EINVAL", "you can't time travel doofus"
	end
	sleep(t)
end

return "sys", sys