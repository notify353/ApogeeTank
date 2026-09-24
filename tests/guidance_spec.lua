local addon = {}
assert(loadfile("Core/Access.lua"))("test", addon)
assert(loadfile("Guidance/Model.lua"))("test", addon)
assert(loadfile("Guidance/API.lua"))("test", addon)
local M, API = addon.Guidance, addon.GuidanceAPI
assert(M.Role("NONE") == "DAMAGER" and M.Role(nil) == nil and M.Role("bad") == nil)
local known = {}
for key in pairs(M.families) do known[key] = { name = key, id = 1 } end
local beginner = { devotion = known.devotion }
local rows = M.Evaluate("PALADIN", M.Role("NONE"), beginner, {})
assert(#rows == 1 and rows[1].spell.name == "devotion")
assert(#M.Evaluate("PALADIN", "DAMAGER", beginner, { devotion = true }) == 0)
rows = M.Evaluate("PALADIN", "HEALER", known, {})
assert(#rows == 1 and rows[1].spell.name == "concentration")
rows = M.Evaluate("PALADIN", "TANK", known, {})
assert(#rows == 1 and rows[1].spell.name == "devotion")
assert(#M.Evaluate("PALADIN", "DAMAGER", beginner, { retribution = true }) == 0)
assert(#M.Evaluate("PALADIN", nil, known, {}) == 0)
assert(#M.Evaluate("PALADIN", "TANK", {}, {}) == 0)
assert(#M.Evaluate("WARRIOR", "TANK", known, {}) == 1)
assert(#M.Evaluate("DRUID", "HEALER", known, {}) == 0)
assert(#M.Evaluate("DRUID", "TANK", known, { bear = true }) == 0)
-- Legacy/general buff identities must never produce advice in any role.
local removed = { righteousness = {}, might = {}, furySeal = {}, fury = {}, shout = {}, mark = {}, gift = {} }
for _, role in ipairs({ "TANK", "HEALER", "DAMAGER" }) do
    for _, class in ipairs({ "PALADIN", "WARRIOR", "DRUID" }) do
        assert(#M.Evaluate(class, role, removed, {}) == 0)
    end
end
for key in pairs(removed) do assert(M.families[key] == nil) end
local combat, calls = false, 0
InCombatLockdown = function() return combat end
UnitGroupRolesAssigned = function() return "NONE" end
assert(API.Role() == "DAMAGER")
UnitGroupRolesAssigned = function() error("restricted") end
assert(API.Role() == nil)
C_UnitAuras = { GetAuraDataByIndex = function() calls = calls + 1; return nil end }
assert(type(API.Active({})) == "table" and calls == 1)
combat = true
assert(API.Active({}) == nil and API.Learn() == nil and calls == 1)
combat = false
C_UnitAuras.GetAuraDataByIndex = function() error("restricted") end
assert(API.Active({}) == nil)
local secret = {}
issecretvalue = function(v) return v == secret end
C_UnitAuras.GetAuraDataByIndex = function() return { name = secret } end
assert(API.Active({}) == nil)
print("Preparation roles, learned-only reminders, class policies and restricted-state guards passed")

Enum = { SpellBookSpellBank = { Player = 0 } }
C_Spell = { GetSpellInfo = function(id) return { name = "spell" .. id } end }
local learned = true
C_SpellBook = {
    GetNumSpellBookSkillLines = function() return 1 end,
    GetSpellBookSkillLineInfo = function() return { itemIndexOffset = 0, numSpellBookItems = 1 } end,
    GetSpellBookItemInfo = function() return { name = "spell465", spellID = 465, iconID = 1, isPassive = false, isOffSpec = false } end,
    IsSpellKnown = function() return learned end,
}
local spells = API.Learn()
assert(spells.devotion and spells.devotion.id == 465)
learned = false
spells = API.Learn()
assert(not spells.devotion, "unlearned spellbook entries must not become advice")
