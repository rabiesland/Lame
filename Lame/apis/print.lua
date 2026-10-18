return "print",function(...)
	local write = mainGlobalTable.term.write
	local args = {}
	for i,v in pairs({...}) do
		args[i] = tostring(v)
	end
	write(table.concat(args,"\t").."\n")
end