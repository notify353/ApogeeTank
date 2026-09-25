local addon = {}
assert(loadfile("Core/Access.lua"))("test", addon)
assert(loadfile("Core/Cooldowns.lua"))("test", addon)
local GetDefaultSpells = addon.CooldownAPI.GetDefaultSpells
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
assert(#defaults == 6 and defaults[1].spellId == 679 and defaults[2].spellId == 20271
    and defaults[3].spellId == 853 and defaults[4].spellId == 20924
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
C_Spell.IsSpellHelpful = function() return false end
assert(addon.CooldownAPI.TargetMacro(679) == "/targetenemy [noharm][dead]\n/cast Spell679")
C_Spell.IsSpellHelpful = function() return true end
assert(addon.CooldownAPI.TargetMacro(679) == nil, "dual-use spell acquired an enemy")
C_Spell.IsSpellHelpful = function() return secret end
assert(addon.CooldownAPI.TargetMacro(679) == nil, "unknown helpful classification acquired an enemy")
C_Spell.IsSpellHelpful = function() return false end
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

-- Exercise actual default identities through persistence and live-view input.
addon.CooldownAPI.GetDefaultSpells = GetDefaultSpells
combat, class = false, "PALADIN"
C_SpellBook.IsSpellKnown = function(id) return known[id] == true end
local rendered
addon.CooldownView.Create = function()
    return { Render = function(entries) rendered = entries end, Hide = function() end }
end
local function Saved(ids, ignored)
    local saved = { version = 2, watched = {}, ignored = {} }
    for _, id in ipairs(ids) do saved.watched[#saved.watched + 1] = { spellId = id } end
    for _, id in ipairs(ignored or {}) do saved.ignored[#saved.ignored + 1] = { spellId = id } end
    return saved
end
local function Start(saved, spells)
    known, ApogeeTankCooldownsDB = spells, saved
    local firstFrame = #frames + 1
    local instance = addon.StartCooldowns(function() end)
    local frame = frames[firstFrame]
    local function Send(event) frame.scripts.OnEvent(frame, event) end
    Send("PLAYER_LOGIN")
    return instance.GetModel(), Send, instance.Refresh
end
local function AssertOrder(selection, ids)
    local entries = selection.GetWatched()
    assert(#entries == #ids, "unexpected selection count")
    local visible = {}
    for _, entry in ipairs(rendered) do
        if entry.watched then visible[#visible + 1] = entry.spellId end
    end
    for index, id in ipairs(ids) do
        assert(entries[index].spellId == id and visible[index] == id,
            "saved/display order differs at slot " .. index)
    end
end
local allKnown = { [679] = true, [20271] = true, [853] = true,
    [26573] = true, [20925] = true, [407632] = true }
local selection, send, refresh = Start(nil, allKnown)
AssertOrder(selection, {679, 20271, 853, 26573, 20925, 407632})
assert(#selection.GetEntries() == 6 and selection.IsWatched(679) and selection.IsWatched(20271))
selection.SetWatched(20271, true); refresh()
selection.SetWatched(679, true); refresh()
AssertOrder(selection, {679, 20271, 853, 26573, 20925, 407632})
selection, send = Start(selection.GetSaved(), allKnown)
AssertOrder(selection, {679, 20271, 853, 26573, 20925, 407632})
known[678] = true; send("SPELLS_CHANGED")
assert(selection.IsWatched(678), "new Holy Strike rank lost explicit opt-in")
allKnown[678] = nil
local legacyRanks = Saved({679, 678, 20271, 853})
allKnown[678] = true
selection = Start(legacyRanks, allKnown)
assert(selection.IsWatched(679) and selection.IsWatched(678)
    and selection.IsWatched(20271), "legacy automatic ranks lost default-on")
assert(legacyRanks.version == 2 and #legacyRanks.watched == 4, "loader mutated supplied legacy data")
allKnown[678] = nil
selection, send = Start(Saved({679, 999, 853, 20271, 26573, 20925, 407632}), allKnown)
AssertOrder(selection, {679, 999, 20271, 853, 26573, 20925, 407632})
local unchangedRevision = selection.GetRevision()
send("PLAYER_REGEN_ENABLED")
assert(selection.GetRevision() == unchangedRevision, "stable defaults caused repeated changes")
selection, send = Start(nil, { [679] = true })
AssertOrder(selection, {679})
known[853] = true; send("SPELLS_CHANGED")
AssertOrder(selection, {679, 853})
known[20271] = true; send("SPELLS_CHANGED")
AssertOrder(selection, {679, 20271, 853})
selection = Start(selection.GetSaved(), known)
AssertOrder(selection, {679, 20271, 853})
selection = Start(Saved({853, 679, 20271}), allKnown)
AssertOrder(selection, {853, 679, 20271, 26573, 20925, 407632})
selection = Start(Saved({679, 853}, {20271}), allKnown)
AssertOrder(selection, {679, 853, 26573, 20925, 407632})
assert(not selection.IsWatched(20271), "ordering discarded Judgement opt-out")
selection, send = Start(Saved({679, 853, 20271}), allKnown)
combat = true
known[678] = true; send("SPELLS_CHANGED")
AssertOrder(selection, {679, 20271, 853, 26573, 20925, 407632})
combat = false; send("PLAYER_REGEN_ENABLED")
assert(selection.IsWatched(678), "new rank discarded default-on choice")
allKnown[678] = nil
local automaticOff = Saved({853}, {679, 20271})
automaticOff.version = 3
selection, send = Start(automaticOff, allKnown)
AssertOrder(selection, {679, 20271, 853, 26573, 20925, 407632})
selection.SetWatched(679, false); send("SPELLS_CHANGED")
selection, send = Start(selection.GetSaved(), allKnown)
assert(not selection.IsWatched(679) and selection.IsWatched(20271), "explicit opt-out was reversed")
known[678] = true; send("SPELLS_CHANGED")
assert(not selection.IsWatched(678), "new rank discarded explicit opt-out")
class = "WARRIOR"
selection = Start(Saved({999, 853, 679}), {})
AssertOrder(selection, {999, 853, 679})
print("Paladin default ordering covers fresh/saved lists, leveling, opt-outs, custom slots and other classes")
