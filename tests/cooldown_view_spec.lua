local addon, frames = {}, {}
local function Frame(_, _, parent)
    local f = { shown = true, parent = parent }
    function f:SetScript(key, fn) self[key] = fn end
    function f:SetSize() end
    function f:SetPoint() end
    function f:SetAllPoints() end
    function f:SetDrawSwipe() end
    function f:SetDrawEdge() end
    function f:SetDrawBling() end
    function f:SetCountdownFont() end
    function f:SetHideCountdownNumbers() end
    function f:SetCooldownFromDurationObject() self.timerWrites = (self.timerWrites or 0) + 1 end
    function f:EnableMouse() end
    function f:SetDesaturated(v) self.gray = v end
    function f:SetTexture(v) self.texture = v end
    function f:SetText(v) self.text = v end
    function f:SetAlpha(v) self.alpha = v end
    function f:SetShown(v) self.shown = v end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false; if self.OnHide then self.OnHide(self) end end
    function f:IsShown() return self.shown end
    frames[#frames + 1] = f
    return f
end
CreateFrame = Frame
addon.Style = { iconSize = 18, iconGap = 2, Icon = function() return Frame() end,
    Text = function() return Frame() end }
assert(loadfile("Cooldowns/View.lua"))("ApogeeTank", addon)
local anchor = Frame()
local view = addon.CooldownView.Create(function() return anchor end)
local entries = { { spellId = 1, watched = true, icon = 1 } }
local function Render(state)
    view.Render(entries, { [1] = state }, 100)
    for _, f in ipairs(frames) do if f.image then return f end end
end
local failures = 0
local function Check(label, fn)
    local ok, err = pcall(fn)
    if not ok then failures = failures + 1; print(label .. ": " .. err) end
end
Check("held charges", function()
    local icon = Render({ enabled = false, charges = 1, start = 100, duration = 10 })
    assert(icon.alpha == 0.4 and icon.label.text == "?", "held charge falsely looks ready")
end)
Check("known charge with unavailable recharge timer", function()
    local icon = Render({ enabled = true, charges = 1, start = 0, duration = 0, unknown = true })
    assert(icon.alpha == 1 and icon.label.text == "1", "readable available charge was discarded")
end)
Check("missing saved artwork", function()
    entries[1].icon = nil
    local icon = Render({ enabled = true, start = 0, duration = 0 })
    assert(icon.image.texture == "Interface\\Icons\\INV_Misc_QuestionMark",
        "saved spell with missing artwork left a blank icon")
end)
assert(failures == 0, tostring(failures) .. " cooldown-view regressions")
print("Held charge and unavailable recharge display regressions passed")

GameTooltip = {
    IsOwned = function(self, icon) return self.owner == icon end,
    SetOwner = function(self, icon) self.owner = icon end,
    SetSpellByID = function(self, id) self.spell = id end,
    Show = function(self) self.shown = true end,
    Hide = function(self) self.shown = false; self.owner = nil end,
}
local icon = Render({ enabled = true, start = 0, duration = 0 })
icon.OnEnter(icon)
assert(GameTooltip.shown and GameTooltip.spell == 1)
entries[1].spellId = 2
view.Render(entries, {}, 100)
assert(not GameTooltip.shown, "rebound icon kept stale tooltip")
icon.OnEnter(icon)
assert(GameTooltip.spell == 2)
view.Hide()
assert(not GameTooltip.shown, "hidden icon retained tooltip")
GameTooltip.owner, GameTooltip.shown = {}, true
icon.OnLeave(icon)
assert(GameTooltip.shown, "icon hid unrelated tooltip")
print("Native cooldown hover, identity rebind and owned-tooltip cleanup passed")

entries[1].spellId = 1
icon = Render({ enabled = true, start = 95, duration = 10 })
assert(icon.image.gray, "active cooldown must desaturate artwork")
icon = Render({ enabled = true, start = 0, duration = 0 })
assert(not icon.image.gray, "ready cooldown remained gray")
icon = Render({ enabled = true, start = 95, duration = 10, charges = 1 })
assert(not icon.image.gray, "available charge falsely grayed out")

local combat, assigned = false, nil
InCombatLockdown = function() return combat end
addon.CreateCooldownActions = function()
    return function(list) assert(not combat); assigned = list end
end
local secureView = addon.CooldownView.Create(function() return anchor end, function() end)
secureView.Render({ { spellId = 679, watched = true } }, {}, 100)
local securedIcon
for _, frame in ipairs(frames) do if frame.image and frame.spellId == 679 then securedIcon = frame end end
assert(securedIcon and assigned[1].spellId == 679)
combat = true
secureView.Render({ { spellId = 853, watched = true } }, {}, 100)
assert(securedIcon.spellId == 679 and assigned[1].spellId == 679)
combat = false
secureView.Render({ { spellId = 853, watched = true } }, {}, 100)
assert(securedIcon.spellId == 853 and assigned[1].spellId == 853)
print("Cooldown visual identity stays aligned with combat-frozen cast action")

icon = Render({ enabled = true, start = 0, duration = 0, castable = false })
assert(icon.image.gray, "unusable ready spell must be gray")
icon = Render({ enabled = true, start = 0, duration = 0, castable = true })
assert(not icon.image.gray, "usable ready spell must recover color")

-- Run actual API availability into actual artwork rendering. A range is not
-- evidence that a ground/self spell needs a unit target.
assert(loadfile("Core/Access.lua"))("test", addon)
assert(loadfile("Core/Cooldowns.lua"))("test", addon)
local hasTarget, inRange, usable, needsPower = false, nil, true, false
local secret = {}
issecretvalue = function(value) return value == secret end
UnitExists = function() return hasTarget end
C_Spell = {
    GetSpellInfo = function(id) return {name = "Spell" .. id, iconID = id} end,
    GetSpellCooldown = function() return {isEnabled = true, isActive = false, startTime = 0, duration = 0} end,
    GetSpellCharges = function() return nil end,
    IsSpellUsable = function() return usable, needsPower end,
    IsSpellInRange = function() return inRange end,
    IsSpellHarmful = function(id) return id == 1 or id == 4 or (id == 5 and secret) or false end,
    IsSpellHelpful = function(id) return id == 2 or id == 4 end,
}
icon = Render(addon.CooldownAPI.Read(1, false))
assert(icon.image.gray and icon.alpha == 0.65, "no-target hostile spell did not gray out")
assert(addon.CooldownAPI.TargetMacro(1) == "/targetenemy [noharm][dead]\n/cast Spell1",
    "no-target visual state disabled acquisition action")
for _, id in ipairs({2, 3, 4, 5}) do
    icon = Render(addon.CooldownAPI.Read(id, false))
    assert(not icon.image.gray, "self/ground/dual-use/unknown spell was dimmed for no target")
end
combat = true
hasTarget = true; inRange = true
icon = Render(addon.CooldownAPI.Read(1, false)); assert(not icon.image.gray)
hasTarget = false; inRange = nil
icon = Render(addon.CooldownAPI.Read(1, false)); assert(icon.image.gray)
hasTarget = secret
icon = Render(addon.CooldownAPI.Read(1, false)); assert(not icon.image.gray, "restricted target state was assumed absent")
hasTarget = true; inRange = false
icon = Render(addon.CooldownAPI.Read(1, false)); assert(icon.image.gray, "range failure was lost")
inRange = true; needsPower = true
icon = Render(addon.CooldownAPI.Read(1, false)); assert(icon.image.gray, "resource failure was lost")
needsPower = false; usable = false
icon = Render(addon.CooldownAPI.Read(1, false)); assert(icon.image.gray, "native unusability was lost")
combat = false
print("No-target hostile spell artwork, unchanged self/ground actions and combat-safe availability passed")

icon = Render({ enabled = true, start = 0, duration = 0, nativeDuration = {},
    unknown = true, realCooldown = true, coolingDown = true, castable = true })
assert(icon.image.gray)
icon = Render({ enabled = true, start = 0, duration = 0, nativeDuration = {},
    unknown = true, coolingDown = true, castable = true })
assert(icon.image.gray, "usability refresh recolored running native cooldown")
icon = Render({ enabled = true, start = 0, duration = 0, castable = true })
assert(not icon.image.gray, "completed cooldown did not restore color")

local object = {}
local stable = { start = 0, duration = 0, enabled = true, nativeDuration = object, coolingDown = true }
local liveIcon = Render(stable)
local writes = liveIcon.cooldown.timerWrites
for i = 1, 100 do
    Render({ start = 0, duration = 0, enabled = true, nativeDuration = object, coolingDown = true, castable = i % 2 == 0 })
end
assert(liveIcon.cooldown.timerWrites == writes, "unchanged native duration reset on state-table replacement")
print("100 native cooldown state replacements: zero timer resets")
