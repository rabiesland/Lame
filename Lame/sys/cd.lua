local args = table.concat({...}," ")
CWD = fs.resolve(CWD.."/"..args)