return "require", function(name)
	local package = mainGlobalTable.package
	local returns = {}
	for _,v in ipairs(package.searchers) do
		local ret,dat = v(name)
		if type(ret) == "string" then
			table.insert(returns,ret)
		else
			if dat ~= ":preload:" then
				table.insert(loaded,ret)
				table.insert(package.loaded,ret)
			end
			return ret(name,dat)
		end
	end
	return nil, "ENOENT", table.concat(returns, ", ")
end