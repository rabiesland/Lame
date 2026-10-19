local env = {}
_G.envvar = {
	path=_SYSTEM_DISK..":Lame/sys/;./",
	root=_SYSTEM_DISK..":",
}

function env.get(k)
	apiAssert(k ~= nil and type(k) == "string","Environment variable keys have to be strings!")
	return envvar[k:lower()]
end

function env.set(k,v)
	apiAssert(k ~= nil and type(k) == "string","Environment variable keys have to be strings!")
	apiAssert((v ~= nil and type(v) == "string") or val == nil,"Environment variables have to be either strings of nil!")
	apiAssert(not k:find("="), "The key cannot contain an equals sign!")
	envvar[k:lower()] = v
end

function env.all()
	local envs = table.create(#envvar)
	for i,_ in pairs(envvar) do
		table.insert(envs,i)
	end
	return i
end

return "env",env