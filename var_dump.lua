local json = require "dkjson"
local S={}
-- file pointer
local file = nil
-- the default file name
local log_name = 'log'

-- checks if a file exists
local function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

-- returns the content of the file
local function get_file_data(file)
    if not file_exists(file) then return {} end
    local lines = {}
    for line in io.lines(file) do 
        lines[#lines + 1] = line
    end
    return lines
end

-- dumps the contents of _G table to the file using JSON encoding
local function write_mem(tbl)
    local z = ""
	local i = 0
    -- iterate all the entries in the _G space
    for k,v in pairs(tbl) do
        if (S[k] == nil) then
            if (type(v) == "function") then
                -- get the file of the function
                local src = debug.getinfo(v).short_src
                -- get the line that the function starts
                local line = debug.getinfo(v).linedefined
                -- get the last line of the function
                local last_line = debug.getinfo(v).lastlinedefined
				-- read the file
				local buffer = get_file_data(src)
				local func_data = ""
                -- extract the required function lines
				for i = line, last_line do
					func_data = func_data .. buffer[i] .. " "
				end
				-- encode the type and the data 
                z = json.encode({type(v), k, json.encode(func_data)})
            elseif (type(v) == "table") then 
                z = json.encode({type(v), k, json.encode(v)})
            else
                z = json.encode{type(v), k, json.encode(v)}
            end
            -- append the encoded entry to the file
            file.write(file, z)
            file.write(file, '\n')
        end
		z = ""
    end
end

-- Prepares the _G and marks the system variables
-- system data are not stored
local function init(log)
    _G["system variables"] = S
    -- mark their field as true, the user vars have this field nil
    for k in pairs(_G) do
        S[k] = true
    end
    if (log ~= nil) then
        log_name = log
    end
end
-- dump the contents of _G to log FILE
-- dumps only the user defined variables on global scope 
-- functions are not dumped
local function dump()
    file = io.open(log_name, 'w')
    write_mem(_G)
    io.close(file)
end

-- loads the log stack file and pushes all its contents in the _G table
-- userdata are not supported
local function parse() 
    local lines = get_file_data(log_name)
    -- print all line numbers and their contents
    for k,v in pairs(lines) do
        local var = ""
        local type_v = ""
        local count = 0
        -- iterate all the serialized data
        for i,v in ipairs(json.decode(v)) do
            -- extract the type of the entry
            -- Each entry holds 3 fields, so we are gonna iterate this for
            -- loop 3 times for each distrinct entry
            if (count == 0) then
                type_v = v
			end
            if (type_v == "table") then
                if (count >= 2) then
                    -- we got the table
                    table = json.decode(v)
                    -- push it to _G
                    _G[var] = table
                end
            elseif (type_v == "function") then
				if (count >= 2) then
                    -- decode the function data
					func = json.decode(v)
					-- create new file and inject our function code 
					f = io.open("hahaxd", "w")
					f:write(func)
					f:close()
					-- execute the file so it creates new entry in the _G
                    -- executing load(function_code) does not create the  
                    -- appropriate entries in _G, or I am very bad at this
					dofile("hahaxd")
					-- remove the file
					os.remove("hahaxd")
				end
            else
                -- not table, push it to _G
                if (count >= 2) then
                    -- replace the key, value to the global state
                    _G[var] = v
                end
            end
            -- we have extracted the type of the entry, get the contents
            if (count == 1) then
                var = v
            end
            -- counter to indicate which field of the three we are reading
            count = count + 1
        end
    end
end

-- the exposed API
return {
    init = init,
    dump = dump,
    parse = parse,
}
