local system = {}

function system.hostname()
	return "Lame "+chip.getMachine()+" ("+chip.getUUID()+")"
end

function system.setHostname(str)
	return nil, "EACCES", "Lame does not support setting the host name."
end

function system.machine()
	chip.getMachine():split(" ")[1]:lower()
end

function system.uptime()
	return chip.getTime() - _START_TIME
end

return "system",system