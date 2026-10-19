local toProbe = ({...})[1] or ""

local l = require("lamecoreutilhelper")

local finalDir = CWD.."/"..toProbe
local split = toProbe:split("/")
local match = "^(.*)"
local match1 = table.remove(split) or ""
local finalDir1 = CWD.."/"..table.concat(split,"/")
if not fs.isDir(finalDir) and fs.isDir(finalDir1) then
	finalDir = finalDir1
	match = "^"..l.makeMatchSafe(match1)
end

local x,y = term.getSize()
local dir,err,err1 = fs.list(finalDir)
if not dir then
	return
end
for _,v in pairs(dir) do
	if not v:match(match) then
		continue
	end
	local stringToPrint = v
	if fs.isDir(finalDir.."/"..v) then
		stringToPrint ..= "/"
	end
	stringToPrint ..= " "
	local xPos = term.getCursorPos()
	if xPos+#stringToPrint > x then
		term.write("\n")
	end
	term.write(stringToPrint)
end