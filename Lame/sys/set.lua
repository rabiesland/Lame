local a = false
local vars1 = {...}
if vars1[1] == "/p" then
	a = true
	table.remove(vars1,1)
end
local vars = table.concat(vars1," ")
local split = vars:split("=")
if #split ~= 1 then
	local var = table.remove(split,1)
	local val = table.concat(split,"=")
	if val:sub(1,1) == '"' then
		val = val:sub(2)
	end
	if not a then
		env.set(var,val)
	else
		term.write(val)
		env.set(var,input())
	end
end