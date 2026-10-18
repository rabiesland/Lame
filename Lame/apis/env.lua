local envVars = {}
local env = {
	path=_SYSTEM_DISK..":Lame/sys/;./"
}

function env.get(k)
	apiAssert(type(k) == "string","Key has to be a string!")
	return envVars[k:lower()]
end

function env.set(k,v)
	apiAssert(type(k) == "string","Key has to be a string!")
	apiAssert(not k:find("="), "The key cannot contain an equals sign!")
	env[k:lower()] = v
end

function env.all()
	return table.copy(envVars)
end

return "env",env