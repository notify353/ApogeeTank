local addon, combat, class = {}, false, "PALADIN"
assert(loadfile("UI/Style.lua"))("test", addon)
assert(loadfile("Threat/Hud.lua"))("test", addon)
assert(loadfile("Core/Access.lua"))("test", addon)
InCombatLockdown = function() return combat end
UnitClass = function() return class, class end
UnitIsDeadOrGhost = function() return false end
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
local learned = addon.SealAPI.Learn()
assert(#learned == 2 and learned[1].spellId == 21084 and learned[2].spellId == 21082,
    "unlearned Fury appeared or known seals lost their order")
learnedFury = true
learned = addon.SealAPI.Learn()
assert(#learned == 3 and learned[1].spellId == 1311649 and learned[2].spellId == 21084
    and learned[3].spellId == 21082, "Fury/Righteousness/Crusader order failed")
-- Synthetic later learned rank: identity comes from the spellbook, not a rank catalog.
spells[#spells + 1] = {name = "Fury", spellID = 999001, iconID = 31}
learned = addon.SealAPI.Learn()
assert(learned[1].spellId == 999001 and learned[1].familyId == 1311649)
table.remove(spells)
for _, id in ipairs({20375, 20164, 20165, 20166}) do
    names[id] = "Other" .. id
    spells[#spells + 1] = {name = names[id], spellID = id, iconID = id}
end
learned = addon.SealAPI.Learn()
for index, id in ipairs({1311649, 21084, 21082, 20375, 20164, 20165, 20166}) do
    assert(learned[index].spellId == id, "other seal family order changed")
end
for index = 1, 4 do table.remove(spells) end
class = "WARRIOR"; assert(#addon.SealAPI.Learn() == 0); class = "PALADIN"
combat = true; assert(addon.SealAPI.Learn() == nil)
local frames, named = {}, {}
local nativeVisibility = false
UIParent = {}
function CreateFrame(kind, name, parent, template)
    local f = { scripts = {}, attributes = {} }
    function f:SetScript(key, value) self.scripts[key] = value end
    function f:RegisterEvent() end
    function f:SetScale(value) assert(not name or not combat); self.scale = value end
    function f:SetSize(w, h) assert(not name or not combat); self.width, self.height = w, h end
    function f:SetPoint(...) assert(not name or not combat); self.point = {...} end
    function f:SetAllPoints() end
    function f:EnableMouse() end
    function f:SetDrawSwipe() end
    function f:SetDrawEdge() end
    function f:SetDrawBling() end
    function f:SetCountdownFont() end
    function f:Hide() assert(not name or not combat or nativeVisibility); self.shown = false end
    function f:Show() assert(not name or not combat or nativeVisibility); self.shown = true end
    function f:SetShown(value) assert(not name or not combat or nativeVisibility); self.shown = value end
    function f:SetCooldownFromDurationObject(value) self.durationObject = value end
    function f:SetCooldown(start, duration) self.timerWrites = (self.timerWrites or 0) + 1; self.start, self.duration = start, duration end
    function f:SetFrameStrata() end
    function f:SetFrameLevel() end
    function f:RegisterForClicks(value) self.clicks = value end
    function f:SetAttribute(key, value) assert(not combat or nativeVisibility); self.attributes[key] = value end
    function f:GetAttribute(key) return self.attributes[key] end
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
local artworkWrites = 0
addon.Style = { Icon = function() return { SetTexture = function(self, value) self.texture = value end,
    SetDesaturated = function(self, value) artworkWrites = artworkWrites + 1; self.gray = value end,
    SetAlpha = function(self, value) artworkWrites = artworkWrites + 1; self.alpha = value end } end }
GameTooltip = {
    IsOwned = function(self, owner) return self.owner == owner end,
    SetOwner = function(self, owner) self.owner = owner end,
    SetSpellByID = function(self, id) self.id = id; self.lines = {} end,
    AddLine = function(self, ...) self.lines[#self.lines + 1] = {...} end,
    Show = function() end, Hide = function(self) self.owner = nil end,
}
assert(loadfile("Seals/Runtime.lua"))("test", addon)
assert(loadfile("Seals/Selection.lua"))("test", addon)
ApogeeTankSealsDB = {version = 2, hidden = {[21082] = false}}
local runtime = addon.StartSeals(addon.ThreatHud.GetSealGeometry)
local driver = frames[1]
driver.scripts.OnEvent(driver, "PLAYER_LOGIN")
assert(not named.ApogeeTankSealAction1, "combat reload created seal buttons")
combat = false; driver.scripts.OnEvent(driver, "PLAYER_REGEN_ENABLED")
local first = assert(named.ApogeeTankSealAction1)
assert(first.width == 22 and first.point[4] == 70.5 and first.point[5] == -21.5)
assert(named.ApogeeTankSealAction2.point[4] == 94.5, "seal row spacing differs from cooldowns")
assert(first.attributes.spell == 1311649 and first.attributes.unit == "player")
assert(first.attributes.type1 == "spell" and first.clicks == "LeftButtonUp")
assert(first.visibility == "[combat][dead] hide; show", "seal visibility is not native combat-gated")
first.scripts.OnEnter(first); assert(GameTooltip.id == 1311649)
assert(GameTooltip.lines[1][1] == " " and GameTooltip.lines[2][1] == "TANK"
    and GameTooltip.lines[2][2] == 1 and GameTooltip.lines[2][3] == 0.82
    and GameTooltip.lines[2][4] == 0.35, "Fury footer differs from Devotion Aura")
for index, id in ipairs({21084, 21082}) do
    local button = named["ApogeeTankSealAction" .. (index + 1)]
    button.scripts.OnEnter(button)
    assert(GameTooltip.id == id and GameTooltip.lines[2][1] == "DPS", "seal DPS footer missing")
    button.scripts.OnLeave(button)
end
first.scripts.OnLeave(first); assert(GameTooltip.owner == nil)
assert(runtime.GetModel().SetWatched(1311649, false)); runtime.Refresh()
assert(first.attributes.spell == 21084 and named.ApogeeTankSealAction2.attributes.spell == 21082,
    "unchecked Fury kept its first slot or disturbed remaining order")
assert(runtime.GetModel().SetWatched(1311649, true)); runtime.Refresh()
assert(first.attributes.spell == 1311649 and first.familyId == 1311649,
    "rechecked Fury did not return to the first slot")
combat = true; learnedFury = false
driver.scripts.OnEvent(driver, "SPELLS_CHANGED")
assert(first.attributes.spell == 1311649, "combat changed seal assignment")
combat = false; driver.scripts.OnEvent(driver, "PLAYER_REGEN_ENABLED")
assert(first.attributes.spell == 21084 and first.familyId == 21084)
first.scripts.OnEnter(first)
assert(GameTooltip.id == 21084 and GameTooltip.lines[2][1] == "DPS", "recycled button kept old role footer")
first.scripts.OnLeave(first)
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
combat = false
driver.scripts.OnEvent(driver, "UNIT_AURA", "player")
assert(first.timer.shown and first.timer.start == 100 and first.timer.duration == 30)
assert(first.image.gray == false and named.ApogeeTankSealAction2.image.gray == true)
local setTimer = first.timer.SetCooldown
first.timer.SetCooldown = function() error("temporarily unavailable timer") end
aura.expirationTime = 140
driver.scripts.OnEvent(driver, "UNIT_AURA", "player")
assert(not first.timer.shown, "failed native timer remained visible")
first.timer.SetCooldown = setTimer
driver.scripts.OnEvent(driver, "UNIT_AURA", "player")
assert(first.timer.shown and first.timer.start == 110,
    "same seal state did not recover after transient timer failure")
local writes = first.timer.timerWrites
local beforeArtwork = artworkWrites
for i = 1, 100 do driver.scripts.OnEvent(driver, "UNIT_AURA", "player") end
assert(first.timer.timerWrites == writes, "unrelated aura updates restarted seal timer")
print("100 unchanged aura events: " .. (artworkWrites - beforeArtwork) .. " seal artwork writes")
assert(artworkWrites == beforeArtwork, "unchanged aura events rewrote identical seal artwork state")
local object = {}
aura.duration, aura.expirationTime = secret, secret
C_UnitAuras.GetAuraDuration = function() return object end
driver.scripts.OnEvent(driver, "UNIT_AURA", "player")
assert(first.timer.durationObject == object and first.timer.shown)
restricted = true
local before = reads
combat = true
driver.scripts.OnEvent(driver, "PLAYER_REGEN_DISABLED")
assert(reads == before and not first.timer.shown and not named.ApogeeTankSealAction2.image.gray)
combat = false
restricted = false; aura = nil
driver.scripts.OnEvent(driver, "UNIT_AURA", "player")
assert(not first.timer.shown and not first.image.gray)
aura = { spellId = secret }
driver.scripts.OnEvent(driver, "UNIT_AURA", "player")
assert(not first.timer.shown)
driver.scripts.OnEvent(driver, "PLAYER_LEAVING_WORLD")
assert(not first.timer.shown)
print("Seal native/numeric countdown, restricted-state clearing, expiration and no combat protected writes passed")

driver.scripts.OnEvent(driver, "PLAYER_ENTERING_WORLD")
aura = { spellId = 21084, auraInstanceID = 55, duration = 30, expirationTime = 150 }
UnitIsDeadOrGhost = function() return false end
driver.scripts.OnEvent(driver, "UNIT_AURA", "player")
assert(first.timer.shown)
UnitIsDeadOrGhost = function() error("death status unavailable") end
driver.scripts.OnEvent(driver, "UNIT_AURA", "player")
assert(not first.timer.shown and not named.ApogeeTankSealAction2.image.gray,
    "unknown death status was treated as alive")
print("Seal timers recover after setter failure and clear when eligibility is unknown")

combat = false
UnitIsDeadOrGhost = function() return false end
local selection = runtime.GetModel()
assert(selection.IsWatched(21084) and selection.IsWatched(21082))
local changes = 0
runtime.SetChangedHandler(function() changes = changes + 1 end)
assert(selection.SetWatched(21084, false)); runtime.Refresh()
assert(first.attributes.spell == 21082 and first.attributes.unit == "player")
assert(named.ApogeeTankSealAction2.visibility == "hide"
    and named.ApogeeTankSealAction2.attributes.spell == nil, "hidden seal retained an action")
assert(first.image.gray, "hidden active seal stopped identifying other seals as inactive")
assert(not first.timer.shown and #addon.SealEntries == 2)
local notified = changes
runtime.Refresh()
assert(changes == notified, "unchanged seals triggered picker refresh")
combat = true
assert(not selection.SetWatched(21084, true))
runtime.Refresh()
assert(first.attributes.spell == 21082, "combat visibility change rebound a secure action")
combat = false
driver.scripts.OnEvent(driver, "PLAYER_LEAVING_WORLD")
assert(not selection.SetWatched(21084, true), "zoning allowed selection changes")
driver.scripts.OnEvent(driver, "PLAYER_ENTERING_WORLD")
assert(selection.SetWatched(21082, false)); runtime.Refresh()
assert(first.visibility == "hide" and not first.attributes.spell and not first.timer.shown)
local preserved = ApogeeTankSealsDB
local frameIndex = #frames + 1
local reloaded = addon.StartSeals(addon.ThreatHud.GetSealGeometry)
frames[frameIndex].scripts.OnEvent(frames[frameIndex], "PLAYER_LOGIN")
assert(ApogeeTankSealsDB ~= preserved and not reloaded.GetModel().IsWatched(21084)
    and not reloaded.GetModel().IsWatched(21082), "reload discarded hidden seals")
local future = {version = 99, hidden = {[21084] = true}}
ApogeeTankSealsDB = future
frameIndex = #frames + 1
local blocked = addon.StartSeals(addon.ThreatHud.GetSealGeometry)
frames[frameIndex].scripts.OnEvent(frames[frameIndex], "PLAYER_LOGIN")
assert(blocked.GetModel() == nil and ApogeeTankSealsDB == future)
print("Seal HUD visibility, hidden active aura, guarded secure rebinding and runtime persistence passed")

-- Execute the real exported visibility resolver; the engine condition parser
-- is a fixture, while Show/Hide/statehidden dispatch is actual Blizzard Lua.
local export = os.getenv("APOGEE_FOREVER_EXPORT")
if export and export ~= "" then
    local file = assert(io.open(export .. "/Blizzard_RestrictedAddOnEnvironment/SecureStateDriver.lua", "r"))
    local source = file:read("*a"); file:close()
    local body = assert(source:match("local function resolveDriver(.-)\nend"))
    local chunk = assert(loadstring("return function" .. body .. "\nend"))
    local dead = false
    setfenv(chunk, {tonumber = tonumber, SecureCmdOptionParse = function(values)
        assert(values == "hide" or values == "[combat][dead] hide; show")
        return (values == "hide" or combat or dead) and "hide" or "show"
    end})
    local resolve = chunk()
    local function Apply(button)
        nativeVisibility = true
        resolve(button, "state-visibility", button.visibility)
        nativeVisibility = false
    end
    assert(selection.SetWatched(21084, true)); runtime.Refresh()
    Apply(first)
    assert(first.shown and not first.attributes.statehidden)
    local spell, point = first.attributes.spell, first.point
    combat = true; Apply(first)
    local beforeReads = reads
    driver.scripts.OnEvent(driver, "PLAYER_REGEN_DISABLED")
    driver.scripts.OnEvent(driver, "UNIT_AURA", "player")
    assert(not first.shown and first.attributes.statehidden and not first.timer.shown
        and reads == beforeReads and first.attributes.spell == spell and first.point == point)
    combat = false
    driver.scripts.OnEvent(driver, "PLAYER_REGEN_ENABLED"); Apply(first)
    assert(first.shown and first.attributes.spell == spell and first.point == point)
    Apply(named.ApogeeTankSealAction2)
    assert(not named.ApogeeTankSealAction2.shown, "combat exit restored an unchecked seal")
    dead = true; Apply(first); assert(not first.shown)
    dead = false; Apply(first); assert(first.shown)
    print("Exported native seal visibility hides in combat/death and restores selected OOC actions without insecure writes")
end
