local addon, frames = {}, {}
local methods = {}
function methods:SetSize() end
function methods:CreateTexture() return setmetatable({}, { __index = methods }) end
function methods:SetColorTexture(...) self.color = {...} end
function methods:Show() self.shown = true end
function methods:SetPoint() end
function methods:EnableMouse(value) self.mouse = value end
function methods:SetScript(key, fn) self[key] = fn end
function methods:RegisterEvent() end
function methods:SetTexture(value) self.texture = value end
function methods:SetDesaturated(value) self.gray = value end
function methods:SetAlpha(value) self.alpha = value end
function methods:SetShown(value) self.shown = value end
function methods:Hide() self.shown = false end
function CreateFrame()
    local frame = setmetatable({}, { __index = methods })
    frames[#frames + 1] = frame
    return frame
end
local active
UnitClass = function() return "Paladin", "PALADIN" end
addon.Access = { Call = function(fn, ...) return fn(...) end }
addon.Style = { iconSize = 22, Icon = function(frame)
    frame.image = setmetatable({}, { __index = methods }); return frame.image
end }
addon.GetActiveStanceIcon = function() return active end
GameTooltip = { IsOwned = function() return false end,
    SetOwner = function() end, SetSpellByID = function(self, value) self.spell = value end,
    AddLine = function(self, value) self.lastLine = value end, Show = function() end }
assert(loadfile("Stance/Runtime.lua"))("test", addon)
local controller = addon.StartStance(function() return {} end)
local suggestion = { missing = true, role = "TANK", family = "devotion", spell = { id = 465, name = "Devotion Aura", icon = 123 } }
controller.SetSuggestion(suggestion)
local icon = frames[2]
assert(icon.shown and icon.image.gray and icon.image.alpha == 0.55)
assert(icon.warningEdges[1].shown and icon.warningEdges[1].color[1] == 1)
local shield = icon.image.texture
local originalRead = addon.GetActiveStanceIcon
addon.GetActiveStanceIcon = function() error("pulse queried aura state") end
assert(icon.OnUpdate)
icon.OnUpdate(icon, 0.9)
assert(icon.warningEdges[1].alpha == 1)
assert(math.abs(icon.image.alpha - 0.85) < 0.001 and icon.image.gray)
icon.OnUpdate(icon, 0.9)
assert(math.abs(icon.image.alpha - 0.55) < 0.001)
addon.GetActiveStanceIcon = originalRead
icon.OnEnter()
assert(GameTooltip.spell == 465 and GameTooltip.lastLine == "TANK")
active = 999
frames[1].OnEvent(nil, "UPDATE_SHAPESHIFT_FORM")
assert(icon.shown and not icon.image.gray and icon.alpha == 1 and icon.image.texture == shield and not icon.OnUpdate)
assert(not icon.warningEdges[1].shown and icon.image.alpha == 1)
active = nil
controller.SetSuggestion(nil)
assert(not icon.shown and not icon.OnUpdate, "unknown must stop pulse and missing presentation")
controller.SetSuggestion(suggestion)
controller.SetUnavailable()
assert(icon.shown and not icon.OnUpdate and icon.image.gray, "combat unknown must keep click affordance without missing pulse")
frames[1].OnEvent(nil, "PLAYER_LEAVING_WORLD")
assert(not icon.shown and not icon.OnUpdate)
print("Paladin fixed shield, inactive gray, active color, tooltip and unknown clearing passed")
