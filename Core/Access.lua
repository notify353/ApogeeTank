-- Ordinary Lua consumers must never branch on, index by, or calculate with secrets.
local _, addon = ...
local A = {}
addon.Access = A

function A.CanRead(...)
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        if issecretvalue and issecretvalue(value) then return false end
        if canaccessvalue and not canaccessvalue(value) then return false end
    end
    return true
end

local function Checked(ok, ...)
    if not ok or not A.CanRead(...) then return false end
    return true, ...
end

function A.Try(fn, ...)
    if type(fn) ~= "function" or not A.CanRead(...) then return false end
    return Checked(pcall(fn, ...))
end

function A.Call(fn, ...)
    local function Values(ok, ...)
        if ok then return ... end
    end
    return Values(A.Try(fn, ...))
end

function A.Fields(value, fields)
    if not A.CanRead(value) or type(value) ~= "table" then return false end
    for _, key in ipairs(fields) do
        if not A.CanRead(value[key]) then return false end
    end
    return true
end

-- Resolve globals at read time; do not change Blizzard's global API functions.
function A.Global(name)
    return function(...) return A.Call(_G[name], ...) end
end
