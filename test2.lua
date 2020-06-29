local md = require "var_dump"
-- the file that the data will be stored
md.init()
function bob(a,b)
	return 1
end
md.dump()
bob = "XD"
-- change the value of an already defined variable in _G
md.parse()
-- prints 24 instead of 25
print(bob(1, 2))
