-- Optional review artifact from mock frames created by the actual addon Lua.
-- No real character data or client artwork is read. Not loaded by the addon.
local output = os.getenv("APOGEE_UI_CAPTURE")
if not output or output == "" then return function() end end
local snapshots = {}
local function JSON(value)
    if type(value) == "string" then
        return '"' .. value:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '') .. '"'
    elseif type(value) == "number" or type(value) == "boolean" then return tostring(value)
    elseif type(value) == "table" then
        local parts = {}
        if #value > 0 then
            for _, item in ipairs(value) do parts[#parts + 1] = JSON(item) end
            return "[" .. table.concat(parts, ",") .. "]"
        end
        for key, item in pairs(value) do parts[#parts + 1] = JSON(key) .. ":" .. JSON(item) end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return "null"
end
return function(label, frames, includePicker)
    local ids, nodes = {}, {}
    local function Visit(f)
        if not f then return nil end
        if ids[f] then return ids[f] end
        local id = #nodes + 1
        ids[f] = id
        local node = { id = id, kind = f.kind, name = type(f.name) == "string" and f.name or nil, shown = f:IsShown(), points = {} }
        nodes[id] = node
        node.parent = Visit(f.parent)
        for _, field in ipairs({ "width", "height", "scale", "alpha", "text", "texture", "fontSize",
            "color", "textColor", "barColor", "minimum", "maximum", "barValue", "layer", "frameLevel",
            "strata", "template", "checked", "justify", "backdropColor" }) do
            local value = f[field]
            if type(value) ~= "table" or field:find("[Cc]olor") then node[field] = value end
        end
        if f.allPoints then node.allPoints = Visit(f.allPoints) end
        for _, p in ipairs(f.points) do
            local relative, rp, x, y = p[2], p[3], p[4], p[5]
            if type(relative) ~= "table" then relative, rp, x, y = f.parent, p[1], p[2], p[3] end
            node.points[#node.points + 1] = { p[1], Visit(relative), rp, x or 0, y or 0 }
        end
        return id
    end
    local roots = {}
    for _, f in ipairs(frames) do
        if f.name == "ApogeeTankThreatHud" or f.name == "ApogeeTankTargetMarkerButton"
            or (includePicker and f.name == "ApogeeTankPickerWindow") then roots[f] = true end
    end
    for _, f in ipairs(frames) do
        local ancestor = f
        while ancestor do
            if roots[ancestor] then Visit(f); break end
            ancestor = ancestor.parent
        end
    end
    snapshots[#snapshots + 1] = { label = label, nodes = nodes }
    local file = assert(io.open(output, "w"))
    file:write(JSON(snapshots)); file:close()
end
