local json = require "dkjson"
local S={}
local file = nil
local log_name = 'log'
-- dumps the contents of _G table to the file using JSON encoding
local function write_mem(tbl)
    local z = ""
    for k,v in pairs(tbl) do
        if (S[k] == nil) then
            if (type(v) == "function") then
                -- unused 
                -- z = json.encode({type(v), k})
            elseif (type(v) == "table") then 
                z = json.encode({type(v), k, json.encode(v)})
            else
                z = json.encode{type(v), k, json.encode(v)}
            end
            file.write(file, z)
            file.write(file, '\n')
        end
    end
end

local function __LINE__()
    return debug.getinfo(2, 'l').currentline
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
    file.write(file, json.encode({"line", __LINE__() + 1}))
    file.write(file, "\n");
    write_mem(_G)
    io.close(file);
end

-- checks if a file exists
local function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

-- returns the content of the file
local function get_file_data(file)
    if not file_exists(file) then return {} end
    lines = {}
    for line in io.lines(file) do 
        lines[#lines + 1] = line
    end
    return lines
end

-- loads the log stack file and pushes all its contents in the _G table
-- userdata and functions are not handled
local function parse() 
    local lines = get_file_data(log_name)
    local line = 0
    -- print all line numbers and their contents
    for k,v in pairs(lines) do
        local var = ""
        local type_v = ""
        local table = {}
        count = 0;
        -- iterate all the serialized data
        for i,v in ipairs(json.decode(v)) do
            if (count == 0) then
                type_v = v
            end
            if (type_v == "line") then
                line = tonumber(v)
            elseif (type_v == "table") then
                if (count >= 2) then
                    -- we got the table
                    table = json.decode(v)
                    -- push it to _G
                    _G[var] = table
                end
            else
                -- not table, push it to _G
                if (count >= 2) then
                    _G[var] = v
                end
            end
            if (count == 1) then
                var = v
            end
            count = count + 1;
        end
    end
    return line
end

-- the exposed API
return {
    init = init,
    dump = dump,
    parse = parse,
}
