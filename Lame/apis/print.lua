return "print",function(...)
	local write = mainGlobalTable.term.write
	local args = {}
	for i,v in pairs({...}) do
		table.insert(args,tostring(v) or "nil")
	end
	write(table.concat(args,"\t").."\n")
end