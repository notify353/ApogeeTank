local addon, frames = {}, {}
assert(loadfile("Core/Access.lua"))("test", addon)
local dead, combat, suggestion = false, false, nil
function UnitIsDeadOrGhost() return dead end
function UnitClass() return "Paladin", "PALADIN" end
function InCombatLockdown() return combat end
function CreateFrame()
    local frame = { events = {}, scripts = {} }
    function frame:RegisterEvent(event) self.events[event] = true end
    function frame:SetScript(event, fn) self.scripts[event] = fn end
    function frame:SetSize() end
    function frame:SetPoint() end
    function frame:EnableMouse() end
    function frame:Hide() end
    frames[#frames + 1] = frame
    return frame
end
addon.Style = { Text = function() return {
    SetPoint = function() end, SetWidth = function() end,
    SetJustifyH = function() end, SetTextColor = function() end,
} end }
local spell = { id = 465, name = "Devotion Aura", icon = 1 }
addon.GuidanceAPI = {
    Learn = function() return { devotion = spell }, { Aura = "devotion" } end,
    Role = function() return "TANK" end,
    Active = function() return {} end,
}
addon.Guidance = { Evaluate = function() return { { spell = spell } } end }
assert(loadfile("Guidance/Runtime.lua"))("test", addon)
addon.StartGuidance(function() return {} end, {
    SetSuggestion = function(value) suggestion = value end,
    SetUnavailable = function() end,
})
local driver = frames[1]
local function Event(event)
    if driver.events[event] then driver.scripts.OnEvent(driver, event) end
end
Event("PLAYER_LOGIN")
assert(suggestion and suggestion.missing)
dead = true; Event("PLAYER_DEAD")
assert(suggestion == nil, "death without an aura update left a missing-aura warning")
dead = false; Event("PLAYER_ALIVE")
assert(suggestion and suggestion.missing, "revival did not refresh guidance")
Event("PLAYER_LEAVING_WORLD")
assert(suggestion == nil)
Event("PLAYER_ALIVE")
assert(suggestion == nil, "late revival event restored guidance during zoning")
print("Guidance clears on death, recovers on revival and remains off during zoning")
