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
assert(state.nativeDuration and state.coolingDown == true and state.realCooldown == nil,
    "native display cooldown classification was coupled to discovery event")

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
local gcd = addon.CooldownAPI.Read(679, false)
assert(gcd and gcd.duration == 0 and gcd.coolingDown == false and not gcd.unknown)
print("Restricted GCD-only timestamps stay ready without duration queries")
