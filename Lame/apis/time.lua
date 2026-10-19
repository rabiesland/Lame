local months = {31,28,31,30,31,30,31,31,30,31,30,31}
local monthsLeap = {31,29,31,30,31,30,31,31,30,31,30,31}

local function isLeapYear(i)
	return (i%4 == 0) and not ((i%100 == 0) and not (i%400 == 0))
end
local time = {}

function time.monotonic()
	return chip.getTime()
end

function time.wall()
	return math.floor(chip.getUnixTime())
end

function time.date(s)
	if s == nil then
		s = chip.getUnixTime()
	end
	apiAssert(type(s) == "number", "Time has to be a number!")
	if (s+62167219200) < 0 then --i genuinely don't know how this would happen in the wild but just to be safe
		return {
			year=0,
			month=1,
			day=1,
			hour=0,
			min=0,
			sec=0,
			wday=0,
			yday=1
		}
	end
	s = math.floor(s)+62167219200
	m = math.floor(s / 60)
	s -= m * 60
	h = math.floor(m / 60)
	m -= math.floor(h * 60)
	d = math.floor(h / 24)
	h -= d * 24
	
	y = 0;
	
	local d1 = 0
	
	local month = 1
	local leap = isLeapYear(y)
	local monthsTab = leap and monthsLeap or months
	while true do
		if d/(leap and 366 or 365) >= 1 then
			d-=leap and 366 or 365
			y += 1
			leap = isLeapYear(y)
			monthsTab = leap and monthsLeap or months
			d1 = d
		elseif d > monthsTab[month] then
			d -= monthsTab[month]
			month += 1
		else
			break
		end
	end
	
	d+=1
	d1+=1
	
	-- based on https://en.wikipedia.org/wiki/Zeller's_congruence#Implementations_in_software
	local month2 = month
	local y1 = y
	if month2 < 3 then
		month2 += 12
		y1-=1
	end
	K = (y1 % 100)
	J = math.floor(y1 / 100)
	dow = (d + math.floor((13 * (month2 + 1))/5) + K + math.floor(K/4) + math.floor(J/4) + (5*J)) % 7
	dow = ((dow+5) % 7)+1
	if dow == 7 then
		dow = 0
	end
	
	return {
		year = y,
		month = month,
		day = d,
		hour = h,
		min = m,
		sec = s,
		wday = dow,
		yday = d1
	}
end

return "time", time