--API based on the amazing Lua manuals
--https://www.lua.org/pil/22.1.html
--https://www.lua.org/manual/5.5/
local os = {}
function os.version()
	return chip.version()
end
function os.getenv(var)
	apiAssert(var ~= nil and type(var) == "string","Environment variable keys have to be strings!")
	return envvar[var:lower()]
end
function os.listenv()
	local envs = table.create(#envvar)
	for i,_ in pairs(envvar) do
		table.insert(envs,i)
	end
	return i
end
function os.setenv(var,val)
	apiAssert(var ~= nil and type(var) == "string","Environment variable keys have to be strings!")
	apiAssert((val ~= nil and type(val) == "string") or val == nil,"Environment variables have to be either strings of nil!")
	apiAssert(not var:find("="), "The key cannot contain an equals sign!")
	envvar[var:lower()] = val
end
local months = {
	31,
	28,
	31,
	30,
	31,
	30,
	31,
	31,
	30,
	31,
	30,
	31
}
function os.time(opt)
	if not opt then
		return math.floor(chip.getUnixTime())
	end
	if type(opt) == "boolean" and opt then
		return chip.getLunarTime()
	end
	apiAssert(opt ~= nil and type(opt) == "table", "The time argument has to be a table!")
	apiAssert(opt.year ~= nil and type(opt.year) == "number", "The time table requires a valid year argument!")
	apiAssert(opt.month ~= nil and type(opt.month) == "number", "The time table requires a valid month argument!")
	apiAssert(opt.day ~= nil and type(opt.day) == "number", "The time table requires a valid day argument!")
	local retTime = 0
	opt.year -= 1970
	opt.hour = opt.hour or 12
	opt.min = opt.min or 0
	opt.sec = opt.sec or 0
	retTime += opt.year * 31536000
	if (opt.year+1970) >= 1970 then
		for i=1970,(opt.year+1970) do
			if (i%4 == 0) and not ((i%100 == 0) and not (i%400 == 0)) then
				retTime += 86400
			end
		end
	else
		for i=(opt.year+1970),1970 do
			if (i%4 == 0) and not ((i%100 == 0) and not (i%400 == 0)) then
				retTime -= 86400
			end
		end
	end
	for i=1,opt.month-1 do
		retTime += months[i] * 86400
	end
	retTime += (opt.day-1)*86400
	retTime += opt.hour*3600
	retTime += opt.min*60
	retTime += opt.sec
	return retTime
end

local week = {
	[0] = "Sunday",
	[1] = "Monday",
	[2] = "Tuesday",
	[3] = "Wednesday",
	[4] = "Thursday",
	[5] = "Friday",
	[6] = "Saturday",
}
local monthName = {
	"January",
	"February",
	"March",
	"April",
	"May",
	"June",
	"July",
	"August",
	"September",
	"October",
	"November",
	"December"
}
function os.date(f,t)
	apiAssert(type(f) == "string", "Format has to be a string!")
	if not t then
		t = chip.getUnixTime()
	end
	apiAssert(type(t) == "number", "Time has to be a number!")
	local tab = mainGlobalTable.time.date(t) --im not writing that shit again
	tab.isdst = false
	if f == "*t" then
		return tab
	end
	local weekday = week[tab.wday]
	local month = monthName[tab.month]
	local ampm = tab.hour >= 12 and "pm" or "am"
	local hour12 = (tab.hour + 1) % 12
	if hour12 == 0 then
		hour12 = 12
	end
	local year2 = tab.year % 100
	
	f = f:gsub("%%a",weekday:sub(1,3))
	f = f:gsub("%%A",weekday)
	f = f:gsub("%%b",month:sub(1,3))
	f = f:gsub("%%B",month)
	f = f:gsub("%%c",tab.year.."-"..tab.month.."-"..tab.day.."T"..tab.hour.."-"..tab.min.."-"..tab.sec)
	f = f:gsub("%%H",tab.hour)
	f = f:gsub("%%I",hour12)
	f = f:gsub("%%d",tab.day)
	f = f:gsub("%%m",tab.month)
	f = f:gsub("%%M",tab.min)
	f = f:gsub("%%p",ampm)
	f = f:gsub("%%S",tab.sec)
	f = f:gsub("%%w",tab.wday)
	f = f:gsub("%%x",tab.year.."-"..tab.month.."-"..tab.day)
	f = f:gsub("%%X",tab.hour.."-"..tab.min.."-"..tab.sec)
	f = f:gsub("%%Y",tab.year)
	f = f:gsub("%%y",year2)
	f = f:gsub("%%%%","%%%%")
	
	return f
end
function os.remove(file)
	local suc,resp,err,err1 pcall(mainGlobalTable.fs.delete,file)
	if not suc then
		error(resp,2)
	end
	return resp,err,err1
end

function os.rename(file,file1)
	local suc,resp,err,err1 pcall(mainGlobalTable.fs.rename,file,file1)
	if not suc then
		error(resp,2)
	end
	return resp,err,err1
end

function os.tmpname()
	local final = ""
	for i=1,4 do
		final ..= string.char(math.random(1,26)+64)
	end
	for i=1,4 do
		final ..= math.random(0,9)
	end
	for i=1,4 do
		final ..= string.char(math.random(1,26)+64)
	end
	for i=1,4 do
		final ..= math.random(0,9)
	end
	return mainGlobalTable.fs.resolve(CWD.."/"..final)
end

function os.exit()
	table.remove(programStack)
end

os.execute = addProgramToStack
os.clock = chip.getTime
os.shutdown = chip.shutdown
os.reboot = chip.reboot

return "os", os