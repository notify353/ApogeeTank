local addon, frames = {}, {}
assert(loadfile("Core/Access.lua"))("ApogeeTank", addon)
local now, rendered, apiReads = 100, nil, 0
function GetTime() return now end
function UnitAffectingCombat() return true end
function CreateFrame()
    local f = { scripts = {}, shown = true }
    function f:SetScript(event, fn) self.scripts[event] = fn end
    function f:RegisterEvent() end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false end
    function f:SetShown(value) self.shown = value end
    frames[#frames + 1] = f
    return f
end
local cooldown = { startTime = 100, duration = 1.5, isActive = true,
    isEnabled = true, isOnGCD = true, modRate = 1 }
local charges
C_Spell = {
    GetSpellInfo = function(id) return { name = "Spell " .. id, iconID = id } end,
    GetSpellCooldown = function() apiReads = apiReads + 1; return cooldown end,
    GetSpellCharges = function() return charges end,
}
addon.CooldownView = { Create = function()
    return { Render = function(entries, states) rendered = { entries = entries, states = states } end,
        Hide = function() rendered = nil end }
end }
for _, path in ipairs({ "Core/ObservedSpellList.lua", "Core/Cooldowns.lua", "Cooldowns/Runtime.lua" }) do
    assert(loadfile(path))("ApogeeTank", addon)
end
local runtime = addon.StartCooldowns(function() end)
local driver = frames[1]
local function Event(event, unit, id) driver.scripts.OnEvent(driver, event, unit, "cast", id) end
Event("PLAYER_LOGIN")
Event("UNIT_SPELLCAST_SUCCEEDED", "pet", 1)
Event("SPELL_UPDATE_COOLDOWN")
assert(#runtime.GetModel().GetEntries() == 0, "learned another unit's cast")
Event("UNIT_SPELLCAST_SUCCEEDED", "player", 1)
Event("SPELL_UPDATE_COOLDOWN")
assert(#runtime.GetModel().GetEntries() == 0, "learned global cooldown")
cooldown.duration, cooldown.isOnGCD = 10, false
local beforeLearning = apiReads
Event("SPELL_UPDATE_COOLDOWN")
assert(apiReads - beforeLearning == 1, "newly learned cooldown was queried twice")
assert(runtime.GetModel().IsWatched(1), "real cooldown was not automatically watched")
local reads = apiReads
now = 101
driver.scripts.OnUpdate(driver, 0.1)
assert(apiReads == reads, "countdown animation polled spell APIs")
runtime.GetModel().SetWatched(1, false)
Event("UNIT_SPELLCAST_SUCCEEDED", "player", 1)
Event("SPELL_UPDATE_COOLDOWN")
assert(not runtime.GetModel().IsWatched(1), "recast ignored an explicit uncheck")
local restored = addon.ObservedSpellList.Create(ApogeeTankCooldownsDB)
assert(not restored.IsWatched(1) and #restored.GetEntries() == 1, "opt-out did not persist")
runtime.GetModel().Clear()
runtime.Clear()
Event("SPELL_UPDATE_COOLDOWN")
assert(#runtime.GetModel().GetEntries() == 0, "clear relearned a pending cast")
charges = { currentCharges = 1, maxCharges = 2, cooldownStartTime = 101,
    cooldownDuration = 8, chargeModRate = 1, isActive = true }
Event("UNIT_SPELLCAST_SUCCEEDED", "player", 2)
Event("SPELL_UPDATE_CHARGES")
assert(runtime.GetModel().IsWatched(2) and rendered.states[2].charges == 1,
    "charge-based cooldown was not learned")
Event("PLAYER_LEAVING_WORLD")
assert(not driver.shown and rendered == nil, "cooldown driver survived world exit")
print("Cooldown discovery, GCD rejection, charges, opt-outs and event-driven reads passed")

function GetNumShapeshiftForms() return 1 end
function GetShapeshiftFormInfo() return 1, false, true, 2 end
Event("UPDATE_SHAPESHIFT_FORMS")
assert(#runtime.GetModel().GetEntries() == 0, "previously learned stance survived exclusion")
Event("UNIT_SPELLCAST_SUCCEEDED", "player", 2)
Event("SPELL_UPDATE_COOLDOWN")
assert(#runtime.GetModel().GetEntries() == 0, "stance was relearned")
Event("UNIT_SPELLCAST_SUCCEEDED", "player", 3)
Event("SPELL_UPDATE_COOLDOWN")
assert(runtime.GetModel().IsWatched(3), "stance filter blocked ordinary abilities")
print("Dynamic stance exclusion and existing-list cleanup passed")

Event("PLAYER_REGEN_ENABLED")
assert(rendered == nil, "cooldowns visible outside combat")
Event("SPELL_UPDATE_COOLDOWN")
assert(rendered == nil, "cooldown event revealed icons outside combat")
Event("PLAYER_REGEN_DISABLED")
assert(rendered, "combat entry did not restore cooldowns")

-- A fresh runtime must restore ready selections without a cooldown event.
charges = nil
cooldown = { startTime = 0, duration = 0, isActive = false,
    isEnabled = true, isOnGCD = false, modRate = 1 }
ApogeeTankCooldownsDB = { watched = { { spellId = 3, name = "Spell 3", icon = 3 } } }
runtime = addon.StartCooldowns(function() end)
driver = frames[#frames]
Event("PLAYER_LOGIN")
assert(rendered.states[3] and rendered.states[3].duration == 0,
    "ready saved cooldown remained unknown after login")
assert(not driver.shown, "ready cooldown kept the update driver awake")
runtime.GetModel().SetWatched(3, false)
runtime.Refresh()
assert(rendered.states[3] == nil, "unchecked cooldown retained cached state")
runtime.GetModel().SetWatched(3, true)
runtime.Refresh()
assert(rendered.states[3] and rendered.states[3].duration == 0,
    "rechecked ready cooldown required an unrelated cooldown event")

-- An unclassified active timer must not become a guessed cooldown.
cooldown.startTime, cooldown.duration, cooldown.isActive = now, 1.5, true
cooldown.isOnGCD = nil
Event("SPELL_UPDATE_COOLDOWN")
assert(rendered.states[3].duration == 0, "unclassified timer replaced known readiness")
runtime.GetModel().SetWatched(3, false)
runtime.Refresh()
runtime.GetModel().SetWatched(3, true)
runtime.Refresh()
assert(rendered.states[3] == nil, "unclassified active timer was inferred on recheck")

-- Held state is meaningful outside cooldown events, and must remain dimmed.
cooldown.isEnabled, cooldown.isActive = false, false
runtime.Refresh()
assert(rendered.states[3] and not rendered.states[3].enabled,
    "held cooldown was discarded")
assert(not driver.shown, "held cooldown kept the update driver awake")

-- Expiration is enforced by the event handler even before the next frame tick.
runtime.GetModel().Clear()
runtime.Clear()
Event("UNIT_SPELLCAST_SUCCEEDED", "player", 4)
now = now + 10
cooldown.isEnabled, cooldown.isActive, cooldown.isOnGCD = true, true, false
cooldown.startTime, cooldown.duration = now, 20
local beforeExpired = apiReads
Event("SPELL_UPDATE_COOLDOWN")
assert(apiReads == beforeExpired, "expired discovery candidate was queried")
assert(#runtime.GetModel().GetEntries() == 0, "expired candidate was learned")
assert(not driver.shown, "expired candidate kept the update driver awake")
print("Cooldown initialization, selection refresh, unknown state and expiry regressions passed")

local secret = {}
function issecretvalue(value) return rawequal(value, secret) end
function canaccessvalue(value) return not issecretvalue(value) end
cooldown.duration = secret
Event("UNIT_SPELLCAST_SUCCEEDED", "player", secret)
Event("SPELL_UPDATE_COOLDOWN")
assert(#runtime.GetModel().GetEntries() == 0, "learned restricted spell identity")
Event("UNIT_SPELLCAST_SUCCEEDED", "player", 888)
Event("SPELL_UPDATE_COOLDOWN")
assert(runtime.GetModel().GetEntries()[1].spellId == 888, "public cooldown flag failed learning")
assert(rendered.states[888].unknown, "restricted timer became ready")
runtime.GetModel().SetWatched(888, false)
Event("UNIT_SPELLCAST_SUCCEEDED", "player", 888)
Event("SPELL_UPDATE_COOLDOWN")
assert(not runtime.GetModel().GetEntries()[1].watched, "beta reobservation lost opt-out")
print("Beta cooldown classification, restricted identity and persistent opt-out passed")
