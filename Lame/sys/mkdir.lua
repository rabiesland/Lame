local path = table.concat({...}," ")
print(fs.makeDir(CWD.."/"..path))