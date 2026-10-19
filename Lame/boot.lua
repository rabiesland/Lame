local split = {}
for v in string.gmatch(files.getBootPath(0), "([^:]+)") do
    table.insert(split, v)
end
local datFile = files.open(split[1]..":/Lame/lamekernel.lua","r")
local dat = datFile.read("a")
local prog,err = load(dat,"KERNEL")
if not prog then
	chip.crash(err)
end
prog(files.getDiskID(0):sub(28,36)..":"..split[1])