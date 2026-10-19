local num = tonumber(({...})[1]) or 0.25
while true do
	sys.sleep(num)
	print("sys.sleep("..num..")")
end