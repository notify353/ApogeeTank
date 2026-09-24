local addon = {}
assert(loadfile("Core/Access.lua"))("test", addon)
assert(loadfile("Core/Cooldowns.lua"))("test", addon)
local combat, class = false, "PALADIN"
local known = { [679] = true, [853] = true }
InCombatLockdown = function() return combat end
UnitClass = function() return class, class end
Enum = { SpellBookSpellBank = { Player = 0 } }
C_SpellBook = { IsSpellKnown = function(id) return known[id] == true end }
C_Spell = { GetSpellInfo = function(id) return { name = "Spell" .. id, iconID = id } end }
local defaults = addon.CooldownAPI.GetDefaultSpells()
assert(#defaults == 2 and defaults[1].spellId == 679 and defaults[2].spellId == 853)
known[678] = true
assert(addon.CooldownAPI.GetDefaultSpells()[1].spellId == 678)
known = { [679] = true, [853] = true, [20271] = true, [26573] = true,
    [20924] = true, [20925] = true, [20928] = true, [407632] = true }
defaults = addon.CooldownAPI.GetDefaultSpells()
assert(#defaults == 6 and defaults[3].spellId == 20271 and defaults[4].spellId == 20924
    and defaults[5].spellId == 20928 and defaults[6].spellId == 407632)
known = {}
assert(#addon.CooldownAPI.GetDefaultSpells() == 0)
combat = true
C_SpellBook.IsSpellKnown = function() error("combat spellbook query") end
assert(#addon.CooldownAPI.GetDefaultSpells() == 0)
combat, class = false, "WARRIOR"
assert(#addon.CooldownAPI.GetDefaultSpells() == 0)
print("Paladin default cooldown identities, highest known ranks and combat guards passed")

C_Spell.IsSpellUsable = function() return false, true end
C_Spell.IsSpellInRange = function() return true end
assert(addon.CooldownAPI.Castable(679) == false)
C_Spell.IsSpellUsable = function() return true, false end
C_Spell.IsSpellInRange = function() return false end
assert(addon.CooldownAPI.Castable(679) == false)
C_Spell.IsSpellInRange = function() return nil end
assert(addon.CooldownAPI.Castable(679) == true, "non-ranged spells should use native usability")
C_Spell.IsSpellUsable = function() error("unavailable") end
assert(addon.CooldownAPI.Castable(679) == nil)

local secret = {}
issecretvalue = function(value) return value == secret end
C_Spell.GetSpellCooldown = function() return { isEnabled = true, isActive = true,
    isOnGCD = false, startTime = secret, duration = secret, modRate = 1 } end
C_Spell.GetSpellCharges = function() return nil end
C_Spell.GetSpellCooldownDuration = function() return {} end
local state = addon.CooldownAPI.Read(679, false)
assert(state.nativeDuration and state.coolingDown == nil and state.realCooldown == nil,
    "non-cooldown event trusted potentially stale GCD classification")

C_Spell.IsSpellHarmful = function() return true end
assert(addon.CooldownAPI.TargetMacro(679) == "[harm,nodead] /cast Spell679; /targetenemy\n/cast Spell679")
C_Spell.IsSpellHarmful = function() return false end
assert(addon.CooldownAPI.TargetMacro(679) == nil, "helpful spell acquired an enemy")
C_Spell.IsSpellHarmful = function() return secret end
assert(addon.CooldownAPI.TargetMacro(679) == nil, "unknown classification acquired an enemy")
C_Spell.IsSpellHarmful = function() return true end
C_Spell.GetSpellInfo = function() return { name = "Bad\n/targetenemy" } end
assert(addon.CooldownAPI.TargetMacro(679) == nil, "multiline spell name accepted")
combat = true
C_Spell.IsSpellHarmful = function() error("combat classification") end
assert(addon.CooldownAPI.TargetMacro(679) == nil)
print("Offensive auto-target compilation, helpful/unknown guards and combat query deferral passed")

combat = false
C_Spell.GetSpellInfo = function(id) return { name = "Spell" .. id, iconID = id } end
C_Spell.GetSpellCooldown = function() return { isEnabled = true, isActive = true,
    isOnGCD = true, startTime = secret, duration = secret, modRate = secret } end
C_Spell.GetSpellCharges = function() return nil end
C_Spell.GetSpellCooldownDuration = function() error("GCD-only spell queried duration") end
local gcd = addon.CooldownAPI.Read(679, true)
assert(gcd and gcd.duration == 0 and gcd.coolingDown == false and not gcd.unknown)
print("Restricted GCD-only timestamps stay ready without duration queries")

local stale = addon.CooldownAPI.Read(679, false)
assert(stale and stale.unknown and stale.coolingDown == nil and not stale.gcdOnly,
    "stale GCD flag outside cooldown event falsely asserted readiness")
C_Spell.GetSpellCooldown = function() return { isEnabled = true, isActive = true,
    isOnGCD = false, startTime = 100, duration = 10, modRate = 1 } end
stale = addon.CooldownAPI.Read(679, false)
assert(stale and stale.realCooldown == nil and stale.coolingDown == nil and stale.gcdOnly == nil,
    "readable non-event timer trusted stale GCD flag")
print("GCD classification is trusted only during its documented event")

-- A rank upgrade inherits the latest known rank's choice, and a later explicit
-- recheck must survive subsequent seeding and another rank upgrade.
local frames, selectedRank = {}, 679
function CreateFrame()
    local frame = { scripts = {} }
    function frame:SetScript(key, fn) self.scripts[key] = fn end
    function frame:RegisterEvent() end
    function frame:Hide() end
    function frame:SetShown() end
    frames[#frames + 1] = frame
    return frame
end
function GetTime() return 100 end
addon.CooldownAPI.GetStanceSpells = function() return {} end
addon.CooldownAPI.WatchRange = function() end
addon.CooldownAPI.GetDefaultSpells = function()
    return { { spellId = selectedRank, name = "Default", icon = 1, ranks = {679, 678, 1866} } }
end
addon.CooldownAPI.Read = function() return nil end
addon.CooldownView = { Create = function() return { Render = function() end, Hide = function() end } end }
assert(loadfile("Core/ObservedSpellList.lua"))("test", addon)
assert(loadfile("Cooldowns/Runtime.lua"))("test", addon)
ApogeeTankCooldownsDB = nil
local runtime = addon.StartCooldowns(function() end)
local driver = frames[1]
local function Event(name) driver.scripts.OnEvent(driver, name) end
Event("PLAYER_LOGIN")
local model = runtime.GetModel()
model.SetWatched(679, false)
selectedRank = 678; Event("SPELLS_CHANGED")
assert(not model.IsWatched(678), "rank upgrade discarded opt-out")
model.SetWatched(678, true)
Event("PLAYER_REGEN_ENABLED")
assert(model.IsWatched(678), "older rank opt-out overrode an explicit current-rank recheck")
selectedRank = 1866; Event("SPELLS_CHANGED")
assert(model.IsWatched(1866), "new rank failed to inherit latest rank's explicit selection")
model.SetWatched(1866, false)
Event("PLAYER_REGEN_ENABLED")
assert(not model.IsWatched(1866), "current rank opt-out was reset")
print("Default rank selection survives rechecks and later upgrades")
