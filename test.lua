local md = require "var_dump"
-- the file that the data will be stored
md.init()
-- define a function that we are going to serialize
function bob(a,b)
	return 1
end
-- define a number that will be serialized
test = 1024
-- local vars will NOT be serialized
local not_seriliazed = "not encoded"
-- seriliaze all the data in the log file
md.dump()
-- change the entry of the function to string
bob = "XD"
-- change the value of an already defined variable in _G
md.parse()
-- bob is restored to function
print(bob(1, 2))
