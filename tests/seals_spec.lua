local addon, combat, class = {}, false, "PALADIN"
assert(loadfile("UI/Style.lua"))("test", addon)
assert(loadfile("Threat/Hud.lua"))("test", addon)
assert(loadfile("Core/Access.lua"))("test", addon)
InCombatLockdown = function() return combat end
UnitClass = function() return class, class end
Enum = { SpellBookSpellBank = { Player = 0 } }
local names = { [21084] = "Righteousness", [21082] = "Crusader", [1311649] = "Fury" }
C_Spell = { GetSpellInfo = function(id) return { name = names[id] } end }
local spells = {
    { name = "Righteousness", spellID = 21084, iconID = 1 },
    { name = "Crusader", spellID = 21082, iconID = 2 },
    { name = "Fury", spellID = 1311649, iconID = 3 },
    { name = "Unrelated", spellID = 9, iconID = 4 },
}
local learnedFury = false
C_SpellBook = {
    GetNumSpellBookSkillLines = function() assert(not combat); return 1 end,
    GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = #spells } end,
    GetSpellBookItemInfo = function(slot) return spells[slot] end,
    IsSpellKnown = function(id) return id ~= 1311649 or learnedFury end,
}
assert(loadfile("Seals/API.lua"))("test", addon)
assert(#addon.SealAPI.Learn() == 2, "unlearned or unrelated spell included")
learnedFury = true
assert(#addon.SealAPI.Learn() == 3)
class = "WARRIOR"; assert(#addon.SealAPI.Learn() == 0); class = "PALADIN"
combat = true; assert(addon.SealAPI.Learn() == nil)
local frames, named = {}, {}
UIParent = {}
function CreateFrame(kind, name, parent, template)
    local f = { scripts = {}, attributes = {} }
    function f:SetScript(key, value) self.scripts[key] = value end
    function f:RegisterEvent() end
    function f:SetScale(value) self.scale = value end
    function f:SetSize(w, h) self.width, self.height = w, h end
    function f:SetPoint(...) self.point = {...} end
    function f:SetAllPoints() end
    function f:EnableMouse() end
    function f:SetDrawSwipe() end
    function f:SetDrawEdge() end
    function f:SetDrawBling() end
    function f:SetCountdownFont() end
    function f:Hide() self.shown = false end
    function f:SetShown(value) self.shown = value end
    function f:SetCooldownFromDurationObject(value) self.durationObject = value end
    function f:SetCooldown(start, duration) self.timerWrites = (self.timerWrites or 0) + 1; self.start, self.duration = start, duration end
    function f:SetFrameStrata() end
    function f:SetFrameLevel() end
    function f:RegisterForClicks(value) self.clicks = value end
    function f:SetAttribute(key, value) assert(not combat); self.attributes[key] = value end
    if name then
        assert(not combat and parent == UIParent and template == "SecureActionButtonTemplate")
        named[name] = f
    end
    frames[#frames + 1] = f
    return f
end
function UnregisterAttributeDriver() assert(not combat) end
function RegisterAttributeDriver(button, key, text)
    assert(not combat)
    local value = text
    if text == "nil" then value = nil else value = tonumber(text) or text end
    button:SetAttribute(key, value)
end
function RegisterStateDriver(button, _, value) assert(not combat); button.visibility = value end
addon.Style = { Icon = function() return { SetTexture = function(self, value) self.texture = value end, SetDesaturated = function(self, value) self.gray = value end, SetAlpha = function(self, value) self.alpha = value end } end }
GameTooltip = {
    IsOwned = function(self, owner) return self.owner == owner end,
    SetOwner = function(self, owner) self.owner = owner end,
    SetSpellByID = function(self, id) self.id = id end,
    Show = function() end, Hide = function(self) self.owner = nil end,
}
assert(loadfile("Seals/Runtime.lua"))("test", addon)
addon.StartSeals(addon.ThreatHud.GetSealGeometry)
local driver = frames[1]
driver.scripts.OnEvent(driver, "PLAYER_LOGIN")
assert(not named.ApogeeTankSealAction1, "combat reload created seal buttons")
combat = false; driver.scripts.OnEvent(driver, "PLAYER_REGEN_ENABLED")
local first = assert(named.ApogeeTankSealAction1)
assert(first.width == 22 and first.point[4] == 70.5 and first.point[5] == -21.5)
assert(named.ApogeeTankSealAction2.point[4] == 94.5, "seal row spacing differs from cooldowns")
assert(first.attributes.spell == 21084 and first.attributes.unit == "player")
assert(first.attributes.type1 == "spell" and first.clicks == "LeftButtonUp")
first.scripts.OnEnter(first); assert(GameTooltip.id == 21084)
first.scripts.OnLeave(first); assert(GameTooltip.owner == nil)
combat = true; learnedFury = false
driver.scripts.OnEvent(driver, "SPELLS_CHANGED")
assert(named.ApogeeTankSealAction3.attributes.spell == 1311649, "combat changed seal assignment")
combat = false; driver.scripts.OnEvent(driver, "PLAYER_REGEN_ENABLED")
assert(named.ApogeeTankSealAction3.visibility == "hide")
assert(not driver.scripts.OnUpdate, "seal row added polling")
print("Learned-only seal row, native tooltips, fixed combat assignments and combat-reload deferral passed")

local secret, restricted, aura, reads = {}, false, nil, 0
issecretvalue = function(value) return value == secret end
C_Secrets = { ShouldSpellAuraBeSecret = function() return restricted end }
C_UnitAuras = {
    GetPlayerAuraBySpellID = function(id) reads = reads + 1; if id == 21084 then return aura end end,
    GetAuraDuration = function() return nil end,
}
aura = { spellId = 21084, auraInstanceID = 55, duration = 30, expirationTime = 130 }
combat = true
driver.scripts.OnEvent(driver, "UNIT_AURA", "player")
assert(first.timer.shown and first.timer.start == 100 and first.timer.duration == 30)
assert(first.image.gray == false and named.ApogeeTankSealAction2.image.gray == true)
local writes = first.timer.timerWrites
for i = 1, 100 do driver.scripts.OnEvent(driver, "UNIT_AURA", "player") end
assert(first.timer.timerWrites == writes, "unrelated aura updates restarted seal timer")
local object = {}
aura.duration, aura.expirationTime = secret, secret
C_UnitAuras.GetAuraDuration = function() return object end
driver.scripts.OnEvent(driver, "UNIT_AURA", "player")
assert(first.timer.durationObject == object and first.timer.shown)
restricted = true
local before = reads
driver.scripts.OnEvent(driver, "PLAYER_REGEN_DISABLED")
assert(reads == before and not first.timer.shown and not named.ApogeeTankSealAction2.image.gray)
restricted = false; aura = nil
driver.scripts.OnEvent(driver, "UNIT_AURA", "player")
assert(not first.timer.shown and not first.image.gray)
aura = { spellId = secret }
driver.scripts.OnEvent(driver, "UNIT_AURA", "player")
assert(not first.timer.shown)
driver.scripts.OnEvent(driver, "PLAYER_LEAVING_WORLD")
assert(not first.timer.shown)
print("Seal native/numeric countdown, restricted-state clearing, expiration and no combat protected writes passed")
