local toProbe = ({...})[1] or ""

local l = require("lamecoreutilhelper")

local split = toProbe:split("/")
local match = "^(.*)"
local match1 = table.remove(split) or ""
local finalDir = CWD.."/"..table.concat(split,"/")
finalDir = finalDir
match = "^"..l.makeMatchSafe(match1)

local dir,err,err1 = fs.list(finalDir)
if not dir then
	return
end
for _,v in pairs(dir) do
	if not v:match(match) then
		continue
	end
	fs.delete(finalDir.."/"..v)
end