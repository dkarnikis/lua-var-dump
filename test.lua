local md = require "var_dump"
-- the file that the data will be stored
md.init("XD")
-- declare some random global variables
a = 24;
b = 42;
-- dump the data into file
md.dump()
-- change the value of an already defined variable in _G
a = 25
-- reset all defined variables to the file state
md.parse()
-- prints 24 instead of 25
print(a)
